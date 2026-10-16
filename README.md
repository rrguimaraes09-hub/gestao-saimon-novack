# Gestão Saimon Novack

Sistema web de gestão de eventos da Saimon Novack Gastronomia: funil comercial, orçamentos com cálculo de custo e CMV, fichas técnicas, insumos e clientes. Projeto pessoal do Rafael Guimarães, sem relação com os sistemas do escritório.

Página estática (`index.html` + `config.js`) com dados no Supabase. Não há build: basta hospedar os arquivos.

## Arquivos

| Arquivo | O que é |
|---|---|
| `index.html` | O app inteiro (tela do protótipo + camada de dados supabase-js + login + aba Usuários) |
| `config.js` | URL do projeto e chave publishable/anon do Supabase |
| `supabase/migrations/*.sql` | Schema do banco, RLS, triggers e realtime |
| `supabase/config.toml` | Configuração do Supabase CLI (gerada por `supabase init`) |
| `prototipo-atual.html` | Protótipo original (base no claude.ai), mantido como referência |

## Primeira configuração (uma vez, pelo Rafael)

O Supabase CLI roda por `npx`, sem instalar nada. O login fica na sua conta pessoal; a chave e a senha do banco não ficam em arquivo.

1. Entrar no CLI e vincular o projeto:

   ```bash
   npx supabase login
   ```

   ```bash
   npx supabase link --project-ref oeutngbawbdnkqokgcoy
   ```

   O `link` pede a senha do banco (a que está com você).

2. Aplicar o schema:

   ```bash
   npx supabase db push
   ```

3. Pegar a chave: Dashboard > Project Settings > API Keys. Copiar a chave **publishable** (`sb_publishable_...`) ou a **anon** legada e colar em `config.js`.

4. Configurar o Auth (Dashboard > Authentication):
   - **URL Configuration**: `Site URL` = `https://rrguimaraes09.github.io/gestao-saimon-novack/`. Em `Redirect URLs`, adicionar esse mesmo endereço, `http://localhost:8080` (para testar na máquina) e o do domínio definitivo quando houver.
   - **Sign In / Providers > Email**: manter ligado. O login é por **link mágico** (sem senha).
   - O e-mail padrão do Supabase tem limite baixo (poucos envios por hora). Para a equipe toda isso basta; se incomodar, configurar SMTP próprio em Authentication > Emails > SMTP Settings.

5. Primeiro acesso: abrir o app, pedir o link com o seu e-mail. **O primeiro usuário que entrar vira admin automaticamente.** Os próximos entram como inativos até serem convidados ou liberados na aba Usuários.

## Rodar localmente

Qualquer servidor estático serve. Exemplo:

```bash
npx -y serve -l 8080 .
```

Abrir `http://localhost:8080`.

## Controle de acesso

- `perfis`: um por usuário do Auth, com `papel` (`admin` ou `equipe`) e `ativo`.
- Só perfil **ativo** lê e grava insumos, fichas, clientes e orçamentos.
- Só **admin** vê e mexe em perfis e convites.
- Anônimo não enxerga nada (sem política e sem privilégio nas tabelas).
- Convite: o admin registra o e-mail na aba Usuários. Quando a pessoa entra com esse e-mail, o perfil já nasce ativo com o papel do convite. Se a pessoa já tinha entrado antes (perfil inativo), o convite ativa na hora.
- O admin não consegue se desativar nem mudar o próprio papel pela tela.

## Realtime e recarga

A tela assina `postgres_changes` das tabelas operacionais, então o que um usuário grava aparece para os outros. Ao voltar para a aba do navegador, o app recarrega tudo, para cobrir eventos perdidos em segundo plano.

## Cópia de segurança

O plano Free do Supabase **não oferece backup para download** e **pausa o projeto após cerca de 7 dias sem atividade** (fica 90 dias para restaurar pelo dashboard). Por isso:

- A aba Usuários tem o botão **Exportar dados**, que baixa tudo em JSON. Combinar com o cliente uma rotina (por exemplo, toda segunda-feira).
- Uso diário normal da equipe já evita a pausa. Em período parado, abrir o app ou o dashboard uma vez por semana.

## LGPD

O campo "restrições e alergias" é dado de saúde (dado pessoal sensível, art. 11 da LGPD). A empresa do Saimon é a controladora; o Rafael, como quem opera a infraestrutura, é operador. Pendências:

- Aviso de privacidade curto para os clientes do studio (finalidade: preparo do evento; contato comercial só com consentimento, que o sistema já registra).
- Termo entre o studio e o operador: finalidade, sigilo, acesso restrito à equipe, devolução ou exclusão dos dados ao fim.

## Publicação

O app está publicado no GitHub Pages, servido direto da raiz da branch `main`:

- Repositório: `https://github.com/rrguimaraes09/gestao-saimon-novack` (público; só há arquivos estáticos e a chave publishable, que é pública por natureza)
- Endereço: **https://rrguimaraes09.github.io/gestao-saimon-novack/**

Publicar uma alteração é só fazer commit e `git push` na `main`; o Pages republica em um ou dois minutos. Nunca commitar a senha do banco nem chave secreta (`service_role`).

### Trocar para o domínio do cliente

1. Criar na raiz do repositório o arquivo `CNAME` com o domínio (por exemplo `eventos.saimonnovack.com.br`), commitar e enviar. No GitHub, em Settings > Pages > Custom domain, o mesmo domínio aparece; marcar **Enforce HTTPS** quando o certificado for emitido.
2. No DNS do cliente, criar um registro `CNAME` apontando esse subdomínio para `rrguimaraes09.github.io`.
3. No Supabase (Authentication > URL Configuration), trocar `Site URL` para o novo endereço e acrescentá-lo em `Redirect URLs`. Manter o endereço antigo do GitHub Pages na lista enquanto alguém ainda usar o link antigo.

## Entrega ao cliente

- Confirmar com o cliente o endereço que aparece no rodapé da proposta e a logo.
- Convidar os administradores do Saimon pela aba Usuários.
- Carga inicial de insumos e fichas, se o cliente mandar planilha.
- Antes de entregar, apagar registros marcados `exemplo`:

  ```sql
  delete from orcamentos where exemplo; delete from clientes where exemplo;
  delete from fichas where exemplo; delete from insumos where exemplo;
  ```
