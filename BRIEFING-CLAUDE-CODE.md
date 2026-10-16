# Gestão Saimon Novack: briefing para continuar no Claude Code

## O que é

Sistema web de gestão de eventos para a Saimon Novack Gastronomia. É projeto pessoal do Rafael, feito para ajudar o cliente, e **não tem relação com os sistemas do escritório**.

O protótipo está pronto e funciona: `prototipo-atual.html`, nesta mesma pasta. Ele tem cinco abas:

- **Funil:** pedido recebido > orçamento enviado > aceito > sinal pago > evento realizado > avaliado > recusado.
- **Orçamentos:** cardápio montado a partir das fichas, cálculo de custo, preço sugerido (insumos ÷ CMV alvo + equipe e logística), CMV real, saldo a receber, lista de compras, ordem de produção e proposta.
- **Fichas técnicas:** receita, rendimento, porções por convidado e insumos.
- **Insumos:** nome, unidade e custo; ao mudar o preço de um insumo, tudo recalcula.
- **Clientes:** aniversários dos próximos 30 dias, prato marcante, restrições e alergias, consentimento para contato comercial e histórico.

Hoje o protótipo grava numa base do próprio claude.ai, por `window.claude.use("db")`, com `db.collection(x).onSnapshot`, `db.doc(path).set` e `.delete`. Essa camada é a que vai ser trocada pelo Supabase.

## Regra absoluta

**Não tocar em nada das organizações "Felipe Albuquerque Advocacia" e "fa-cedentes".** Isso inclui os projetos espaco-do-cliente, esteira-fundos e outros. Trabalhar só no projeto abaixo.

## Projeto Supabase (já criado)

- Organização: **Rafael Guimarães (pessoal)**, plano Free
- Projeto: **gestao-saimon-novack**, ref `oeutngbawbdnkqokgcoy`
- Região: South America (São Paulo), sa-east-1
- RLS automático ligado na criação. Data API ligada.
- A senha do banco está com o Rafael. Não pedir nem gravar em arquivo.

## O que construir

1. **Schema:** tabelas `insumos`, `fichas` (com `fichas_itens` ou itens em jsonb), `clientes`, `orcamentos` (cardápio como array de ids de ficha) e `perfis` (`id` = `auth.users.id`, nome, `papel` com os valores `admin` ou `equipe`). Os campos são os mesmos que o protótipo já usa.
2. **RLS:** usuário autenticado com perfil ativo lê e grava os dados operacionais; só `admin` gerencia perfis e convites; anônimo não vê nada.
3. **Frontend:** manter a tela do protótipo, trocar a camada de dados para supabase-js (com realtime ou recarga após gravar), e criar a tela de login por e-mail e a tela "Usuários" para o admin convidar a equipe.
4. **Repositório e hospedagem:** repositório próprio no GitHub, separado dos do escritório, publicado no mesmo tipo de hospedagem do hub e, depois, num domínio do cliente.
5. **Entrega:** criar os administradores do Saimon, remover os registros marcados `exemplo` e fazer a carga inicial de insumos e fichas, se o cliente mandar planilha.

## Pontos de atenção

- **LGPD:** o campo "restrições e alergias" é dado de saúde, portanto sensível (art. 11). A empresa do Saimon é a controladora e o Rafael é o operador. Prever aviso de privacidade e um termo curto entre os dois, com finalidade, sigilo e devolução dos dados.
- **Plano Free:** projeto parado por cerca de uma semana é pausado e não há backup diário automático. É preciso confirmar na documentação e prever uma exportação periódica.
- **Proposta:** confirmar com o cliente o endereço "Rua Eugênio De Bona Castelan, 539, Criciúma/SC" e a logo.
