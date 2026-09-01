# Roteiro de Apresentacao - Fluxo de Avatar (BFF, Flutter e Supabase)

Duracao sugerida: 8 a 12 minutos

## 1. Abertura (0:00 - 0:40)

Fala sugerida:

"Nesta apresentacao vou mostrar como o avatar funciona ponta a ponta no Vinum: do login no Flutter, passando pelo BFF em Go, ate o Supabase Storage e o retorno para a UI."

Objetivo da parte:

- alinhar que o fluxo atual e automatico (sem upload manual no app)

## 2. Visao de arquitetura (0:40 - 1:40)

Mostre:

- app_vinum (Flutter)
- api-vinum-bff (Go)
- Supabase (Auth + Postgres + Storage)

Fala sugerida:

"O app chama o BFF para perfil. O BFF valida o token, decide se precisa gerar avatar e persiste tudo no Supabase."

Mensagem-chave:

- regra de negocio e seguranca ficam no BFF

## 3. Flutter: gatilho do fluxo (1:40 - 3:20)

Arquivos para abrir:

- lib/feature/auth/data/repository/auth_repository_impl.dart
- lib/feature/profile/data/api/profile_api_service.dart

Mostre os pontos:

1. signIn/signInWithSocial
2. chamada _warmUpProfileForAvatar()
3. GET /v1/me/profile com Bearer token
4. atualizacao de _currentUser.avatarUrl

Fala sugerida:

"Logo apos autenticar, o app faz um warm-up de perfil para garantir que avatar_url venha preenchido e a UI ja entre consistente."

## 4. BFF: rota protegida e perfil agregado (3:20 - 5:10)

Arquivos para abrir:

- internal/presentation/http/router/router.go
- internal/presentation/http/middleware/auth.go
- internal/infrastructure/supabase/token_validator.go
- internal/application/profile/service.go

Mostre os pontos:

1. rota GET /v1/me/profile protegida
2. extracao e validacao de JWT
3. leitura de perfil por user_id autenticado
4. condicao: se avatar_url vazio, aciona avatar service

Fala sugerida:

"A regra e simples: o cliente nunca diz de quem e o perfil. O user_id vem do token validado no middleware."

## 5. BFF: geracao e persistencia de avatar (5:10 - 7:10)

Arquivos para abrir:

- internal/application/avatar/service.go
- internal/infrastructure/supabase/storage_repository.go
- internal/infrastructure/supabase/profile_repository.go

Mostre os pontos:

1. tentativa Gravatar
2. fallback UI Avatars
3. upload em users/<user_id>.png no bucket
4. update de profiles.avatar_url
5. retorno do profile com URL publica

Fala sugerida:

"Se nao existe avatar_url, o BFF provisiona um PNG automaticamente, salva no Storage e grava a URL publica no profile."

Mensagem-chave:

- a request de perfil e best-effort para avatar: erro de avatar nao quebra o endpoint principal

## 6. Supabase: o que precisa existir (7:10 - 8:10)

Mostre:

- database/migrations/001_create_profiles.sql
- database/migrations/003_add_avatar_url.sql
- .env.example do BFF (SUPABASE_STORAGE_BUCKET)

Checklist em fala:

1. tabela profiles ativa
2. coluna avatar_url presente
3. bucket avatars criado e publico
4. service role key configurada no BFF

## 7. Demo ao vivo sugerida (8:10 - 10:30)

Passo a passo:

1. login com usuario sem avatar_url
2. abrir Home/Profile
3. observar requisicao para /v1/me/profile
4. mostrar resposta com avatar_url
5. abrir Storage e mostrar arquivo users/<user_id>.png
6. voltar ao app e mostrar CircleAvatar com imagem

Opcional:

- mostrar logs de fallback: "gravatar not found, falling back to ui-avatars"

## 8. Fechamento (10:30 - 11:30)

Fala sugerida:

"Hoje o avatar no Vinum e auto-provisionado, seguro e centralizado no BFF. O app so consome o avatar_url final e renderiza. Isso reduz complexidade no cliente e padroniza o comportamento entre plataformas."

## 9. Perguntas que podem cair

1. Por que nao fazer upload direto no app?
Resposta: porque a regra atual e provisionamento automatico e centralizado no BFF, com controle de seguranca e contrato unico.

2. O que acontece se Gravatar falhar?
Resposta: fallback para UI Avatars.

3. Se der erro no upload do avatar, o perfil quebra?
Resposta: nao. O endpoint de perfil continua respondendo (best-effort).

4. Onde a URL final do avatar fica salva?
Resposta: na coluna profiles.avatar_url.

5. O avatar aparece em quais telas?
Resposta: Home (botao de avatar) e Profile (CircleAvatar principal).
