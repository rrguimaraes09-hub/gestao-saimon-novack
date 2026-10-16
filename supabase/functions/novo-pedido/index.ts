// Edge Function "novo-pedido": porta de entrada pública do funil.
// A página pedido.html (sem login) envia os dados do formulário para cá; a função valida,
// cria ou reaproveita o cliente pelo telefone e abre um orçamento na etapa "pedido".
// Grava com a chave de serviço (só existe no servidor), então a RLS do app não muda:
// anônimo continua sem acesso direto a nenhuma tabela.
import { createClient } from "npm:@supabase/supabase-js@2.49.4";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const ORIGENS = ["Instagram", "Site", "WhatsApp", "Indicação", "Outro"];
const LIMITE_10MIN = 20; // pedidos criados pela porta pública em 10 minutos, no total

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });

const texto = (v: unknown, max: number) => String(v ?? "").replace(/\s+/g, " ").trim().slice(0, max);
const digitos = (v: unknown) => String(v ?? "").replace(/\D/g, "");
function formatarTelefone(d: string) {
  if (d.length === 13 && d.startsWith("55")) d = d.slice(2);
  if (d.length === 11) return `(${d.slice(0, 2)}) ${d[2]} ${d.slice(3, 7)}-${d.slice(7)}`;
  if (d.length === 10) return `(${d.slice(0, 2)}) ${d.slice(2, 6)}-${d.slice(6)}`;
  return d;
}
const dataBR = (iso: string) => iso ? iso.slice(0, 10).split("-").reverse().join("/") : "a definir";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json(405, { ok: false, erro: "Método não permitido." });

  let b: Record<string, unknown>;
  try { b = await req.json(); } catch { return json(400, { ok: false, erro: "Corpo inválido." }); }

  // Campo-armadilha: humano não vê, robô preenche. Responde como sucesso e não grava nada.
  if (texto(b.site, 10)) return json(200, { ok: true, ignorado: true });

  const nome = texto(b.nome, 80);
  const tel = digitos(b.telefone);
  const tipoEvento = texto(b.tipoEvento, 60);
  const cidade = texto(b.cidade, 60);
  const mensagem = texto(b.mensagem, 500);
  const convidados = Math.round(Number(b.convidados) || 0);
  const origemPedida = texto(b.origem, 20);
  const origem = ORIGENS.find((o) => o.toLowerCase() === origemPedida.toLowerCase()) ?? "Site";
  const dataIso = /^\d{4}-\d{2}-\d{2}$/.test(String(b.data ?? "")) && !isNaN(Date.parse(String(b.data))) ? String(b.data) : null;

  if (nome.length < 2) return json(400, { ok: false, erro: "Informe seu nome." });
  if (tel.length < 10 || tel.length > 13) return json(400, { ok: false, erro: "Informe um WhatsApp válido, com DDD." });
  if (!tipoEvento) return json(400, { ok: false, erro: "Informe o tipo de evento." });
  if (convidados < 1 || convidados > 5000) return json(400, { ok: false, erro: "Informe o número aproximado de convidados." });

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  // Freio simples contra enxurrada: conta os pedidos recentes vindos da porta pública.
  const ha10min = new Date(Date.now() - 10 * 60_000).toISOString();
  const { count } = await sb.from("orcamentos").select("id", { count: "exact", head: true })
    .eq("etapa", "pedido").gte("criado_em", ha10min);
  if ((count ?? 0) >= LIMITE_10MIN) return json(429, { ok: false, erro: "Muitos pedidos agora. Tente de novo em alguns minutos." });

  const telefone = formatarTelefone(tel);
  const hoje = new Date().toLocaleDateString("pt-BR", { timeZone: "America/Sao_Paulo" });
  const notaPedido = `Pedido pelo ${origem.toLowerCase() === "instagram" ? "Instagram" : "site"} em ${hoje}` +
    (mensagem ? `: ${mensagem}` : ".");

  // Cliente: procura pelo telefone (últimos 8 dígitos, qualquer formatação) e confere os dígitos.
  const { data: candidatos, error: e1 } = await sb.from("clientes").select("id, nome, telefone, notas")
    .ilike("telefone", `%${tel.slice(-8).replace(/(\d{4})(\d{4})$/, "$1%$2")}%`).limit(20);
  if (e1) return json(500, { ok: false, erro: "Não foi possível consultar o cadastro." });
  const existente = (candidatos ?? []).find((c) => digitos(c.telefone).endsWith(tel.slice(-10)));

  let clienteId: string;
  if (existente) {
    clienteId = existente.id;
    const notas = [existente.notas, notaPedido].filter(Boolean).join("\n");
    await sb.from("clientes").update({ notas }).eq("id", clienteId);
  } else {
    const { data: c, error: e2 } = await sb.from("clientes")
      .insert({ nome, telefone, origem, notas: notaPedido }).select("id").single();
    if (e2 || !c) return json(500, { ok: false, erro: "Não foi possível registrar o contato." });
    clienteId = c.id;
  }

  // Mesmo telefone com pedido aberto nas últimas 24 h: não duplica o cartão.
  const ha24h = new Date(Date.now() - 24 * 3_600_000).toISOString();
  const { data: aberto } = await sb.from("orcamentos").select("id")
    .eq("cliente", clienteId).eq("etapa", "pedido").gte("criado_em", ha24h).limit(1).maybeSingle();
  if (aberto) return json(200, { ok: true, id: aberto.id, repetido: true });

  const { data: o, error: e3 } = await sb.from("orcamentos").insert({
    cliente: clienteId,
    servico: "Evento gastronômico",
    tipo_evento: tipoEvento,
    data: dataIso,
    cidade,
    convidados,
    origem,
    etapa: "pedido",
  }).select("id").single();
  if (e3 || !o) return json(500, { ok: false, erro: "Não foi possível abrir o pedido." });

  return json(200, { ok: true, id: o.id, resumo: `${tipoEvento} em ${dataBR(dataIso ?? "")} para ${convidados} pessoas` });
});
