// Configuração do Supabase (projeto gestao-saimon-novack, organização pessoal).
// A chave publishable/anon é pública por natureza: a proteção dos dados é a RLS do banco.
// Onde pegar: Dashboard > Project Settings > API Keys (chave "publishable" sb_publishable_... ou a "anon" legada).
window.SN_CONFIG = {
  url: "https://oeutngbawbdnkqokgcoy.supabase.co",
  anonKey: "sb_publishable_-jkMekvjBQ662zJ6iN0Drg_cZ7rviiU",
  // Porta de entrada pública (pedido.html): WhatsApp do studio que recebe os contatos, com DDI e DDD,
  // só dígitos (ex.: "5548999999999"). Vazio = a página agradece sem abrir o WhatsApp.
  whatsapp: "",
  // Mensagem que chega pronta no WhatsApp. Marcadores: {nome} {tipo} {data} {convidados}.
  mensagemWhatsApp: "Oi! Sou {nome} e quero um orçamento para {tipo} em {data}, para cerca de {convidados} pessoas.",
};
