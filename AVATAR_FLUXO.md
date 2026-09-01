# Documento Tecnico - Fluxo de Avatar (Flutter -> BFF -> Supabase)

## Objetivo

Explicar como o avatar do usuario e provisionado e exibido hoje no Vinum, cobrindo ponta a ponta:

1. Flutter (app)
2. BFF em Go
3. Supabase (Auth, Postgres e Storage)

## Resumo executivo

O app nao envia imagem de avatar manualmente. O fluxo atual e de provisionamento automatico:

1. Usuario autentica no app.
2. Flutter chama o endpoint protegido GET /v1/me/profile no BFF.
3. Se avatar_url estiver vazio no profile, o BFF gera um avatar:
   - tenta Gravatar pelo email;
   - se nao existir, usa UI Avatars com base no nome.
4. BFF faz upload do PNG no Supabase Storage (bucket publico).
5. BFF salva a URL publica em profiles.avatar_url.
6. Flutter recebe avatar_url e renderiza via NetworkImage.

## Componentes e responsabilidades

| Camada | Responsabilidade |
|---|---|
| Flutter | Login, warm-up de perfil e renderizacao do avatar |
| BFF | Validar JWT, buscar perfil agregado, gerar avatar se ausente |
| Supabase Auth | Emissao/validacao de sessao (JWT) |
| Supabase Postgres | Persistir profiles e avatar_url |
| Supabase Storage | Armazenar arquivo PNG do avatar e expor URL publica |

## Pre-requisitos de configuracao

### Flutter

Variaveis usadas no bootstrap:

- SUPABASE_URL
- SUPABASE_ANON_KEY
- BFF_API_URL

Arquivos principais:

- lib/main_dev.dart
- lib/main_prod.dart
- lib/environment/environment_dev.dart
- lib/core/di/vinum_container.dart

### BFF

Variaveis usadas para avatar:

- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_JWT_SECRET
- SUPABASE_SERVICE_ROLE_KEY
- SUPABASE_STORAGE_BUCKET (default: avatars)

Arquivos principais:

- internal/platform/config/config.go
- internal/bootstrap/app.go
- internal/infrastructure/supabase/storage_repository.go

### Supabase

- Tabela profiles criada na migration 001_create_profiles.sql.
- Coluna avatar_url adicionada na migration 003_add_avatar_url.sql.
- Bucket de Storage (ex: avatars) deve existir e estar publico para servir URL direta.

## Fluxo ponta a ponta (detalhado)

## 1) Autenticacao no app

No Flutter, ha dois caminhos:

1. Email/senha com Supabase SDK (signInWithPassword).
2. Social via BFF (POST /v1/auth/social/exchange).

Arquivos:

- lib/feature/auth/data/repository/auth_repository_impl.dart
- lib/feature/auth/data/api/auth_api_service.dart

## 2) Warm-up de perfil para avatar

Apos login, o app chama _warmUpProfileForAvatar(), que faz:

- GET /v1/me/profile
- Header Authorization: Bearer <access_token>

Se a resposta vier com avatar_url, _currentUser e atualizado com essa URL.

Arquivos:

- lib/feature/auth/data/repository/auth_repository_impl.dart
- lib/feature/profile/data/api/profile_api_service.dart

## 3) Entrada no BFF e validacao JWT

A rota GET /v1/me/profile e protegida por middleware JWTAuth.

Fluxo:

1. Extrai token Bearer.
2. Valida assinatura HMAC com SUPABASE_JWT_SECRET.
3. Extrai claims.Subject (user_id autenticado).

Arquivos:

- internal/presentation/http/router/router.go
- internal/presentation/http/middleware/auth.go
- internal/infrastructure/supabase/token_validator.go

## 4) Leitura de perfil agregado

ProfileService chama o repositorio para ler profiles pelo user_id autenticado.

- select id,email,full_name,phone,role,avatar_url
- usa apikey anon + Authorization com token do usuario (RLS)

Arquivo:

- internal/infrastructure/supabase/profile_repository.go

## 5) Regra de provisionamento de avatar

Se profile.AvatarURL estiver vazio, o BFF faz provisionamento best-effort:

1. Tenta baixar Gravatar com hash MD5 do email.
2. Em fallback, baixa imagem de UI Avatars baseada em full_name.
3. Faz upload no Storage em users/<user_id>.png.
4. Gera URL publica.
5. Salva avatar_url na tabela profiles.

Importante: se essa etapa falhar, a request principal de perfil nao quebra.

Arquivo:

- internal/application/avatar/service.go
- internal/application/profile/service.go

## 6) Upload no Supabase Storage

O BFF envia PUT para:

- /storage/v1/object/{bucket}/users/{user_id}.png

Com headers usando service role key.

Em sucesso, monta a URL publica:

- /storage/v1/object/public/{bucket}/users/{user_id}.png

Arquivo:

- internal/infrastructure/supabase/storage_repository.go

## 7) Persistencia da URL no profile

BFF executa PATCH em /rest/v1/profiles?id=eq.<user_id> com payload:

{
  "avatar_url": "https://.../storage/v1/object/public/avatars/users/<user_id>.png"
}

Com service role key (bypass de RLS).

Arquivo:

- internal/infrastructure/supabase/profile_repository.go

## 8) Resposta para o app

O endpoint /v1/me/profile retorna o perfil agregado com avatar_url:

{
  "user_id": "uuid",
  "email": "user@mail.com",
  "full_name": "Nome Usuario",
  "phone": null,
  "role": "user",
  "avatar_url": "https://..."
}

Arquivo:

- internal/domain/profile/entity.go

## 9) Renderizacao no Flutter

A UI usa user.avatarUrl para montar NetworkImage:

- Home: UserAvatarButton
- Profile: CircleAvatar em ProfilePage

Se avatarUrl for nulo/vazio, cai no fallback de iniciais.

Arquivos:

- lib/feature/profile/presentation/widget/user_avatar_button.dart
- lib/feature/profile/presentation/page/profile_page.dart
- lib/feature/home/presentation/page/home_page.dart

## Sequencia resumida

1. Login no app.
2. App chama GET /v1/me/profile.
3. BFF valida JWT e le profile.
4. avatar_url vazio -> gera imagem.
5. Upload no Storage + update em profiles.
6. BFF responde profile com avatar_url.
7. Flutter atualiza usuario em memoria e renderiza NetworkImage.

## Pontos de atencao

1. O app nao possui upload manual de avatar; tudo e automatico no backend.
2. O provisionamento depende de bucket publico e service role key configurada.
3. A geracao e feita apenas quando avatar_url esta vazio.
4. O fluxo e best-effort: erro de avatar nao derruba /v1/me/profile.

## Checklist rapido de validacao

1. Confirmar bucket avatars publico no Supabase Storage.
2. Confirmar avatar_url existe em public.profiles (migration 003).
3. Fazer login com usuario novo.
4. Chamar /v1/me/profile e verificar avatar_url na resposta.
5. Confirmar arquivo users/<user_id>.png no bucket.
6. Validar exibicao do avatar na Home e na tela de Perfil.
