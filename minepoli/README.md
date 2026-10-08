# MINEPOLI — Urna Online

Aplicação Next.js + Supabase/PostgreSQL para votação centralizada.

## Instalação
1. Crie um projeto no Supabase.
2. Execute `sql/schema.sql` no SQL Editor.
3. Copie `.env.example` para `.env.local` e preencha as chaves.
4. `npm install`
5. `npm run dev`
6. Para produção: `npm run build && npm start` ou faça deploy na Vercel/infra compatível.

## Observações de segurança
- A chave `SUPABASE_SERVICE_ROLE_KEY` nunca deve ir para o navegador.
- O voto é registrado por função PostgreSQL transacional, com bloqueio lógico do eleitor e restrição única.
- Resultados públicos são agregados; a API pública não expõe a relação CPV → candidato.
- O login de demonstração administrativo precisa ser substituído por autenticação de produção com sessão HttpOnly/Supabase Auth antes de uso público.
