# Roteiro — Implementacao de Tags, Autenticacao e Avaliacoes

---

## ABERTURA (0:00 - 0:35)

> [camera]

"Hoje eu vou focar em tres partes essenciais do Vinum: autenticacao com JWT, implementacao de avaliacoes e implementacao de tags. A ideia e mostrar o fluxo completo, do app Flutter ate o BFF em Go e o Supabase, com foco em seguranca e regra de negocio."

---

## PARTE 1 — VISAO RAPIDA DA ARQUITETURA (0:35 - 1:20)

> [abrir estrutura do projeto]

"Temos tres pecas trabalhando juntas:

1. App Flutter: captura login, envia requisicoes e renderiza tela de review.
2. BFF em Go: valida token, aplica regra de negocio e conversa com Supabase.
3. Supabase: auth, banco e funcoes SQL para persistencia transacional.

O ponto principal e: o app nao fala direto com o banco nem com regras sensiveis. Tudo passa pelo BFF."

---

## PARTE 2 — AUTENTICACAO SOCIAL E EMISSAO DE JWT (1:20 - 4:20)

> [abrir login_page.dart e auth_repository_impl.dart]

"No login social, o app usa Google Sign-In para obter um id_token. Esse id_token e enviado para o endpoint do BFF:

POST /v1/auth/social/exchange

No BFF, o fluxo e:

1. Handler recebe provider e id_token.
2. Service valida provider permitido e campos obrigatorios.
3. Repository chama Supabase em auth/v1/token?grant_type=id_token.
4. Supabase retorna access_token, refresh_token, expires_in e user.

O app salva access e refresh token no repositorio de autenticacao e usa o access token nas rotas protegidas."

---

## PARTE 3 — COMO O JWT E VALIDADO NO BFF (4:20 - 6:50)

> [abrir middleware auth.go e token_validator.go]

"As rotas protegidas passam pelo middleware JWTAuth.

O middleware:

1. Extrai Authorization Bearer.
2. Chama o TokenValidator.
3. Injeta claims no contexto da requisicao.

A validacao do token tem duas etapas:

1. Validacao local com SUPABASE_JWT_SECRET.
2. Se falhar, fallback no Supabase via GET /auth/v1/user.

Quando valida, o subject do token vira claims.Subject, e esse valor identifica o usuario autenticado em toda regra sensivel."

---

## PARTE 4 — AUTORIZACAO NA PRATICA (6:50 - 8:00)

> [abrir avaliacao_handler.go e service.go de avaliacao]

"Create, update e delete de review nao confiam em usuario_id vindo do cliente.

O BFF pega o usuario autenticado do claims.Subject.

Depois, no update e delete, ele compara o dono da avaliacao com esse subject. Se for diferente, retorna forbidden.

Isso evita que um usuario altere ou exclua avaliacao de outro usuario, mesmo tentando forjar payload."

---

## PARTE 5 — REFRESH E LOGOUT (8:00 - 8:50)

> [abrir auth_repository_impl.dart e auth_handler.go]

"Existe endpoint de refresh no BFF:

POST /v1/auth/refresh

Ele troca refresh_token por nova sessao.

No logout:

POST /v1/auth/logout

O app envia Bearer access token, o BFF chama o Supabase para encerrar sessao e depois limpa estado local no app."

---

## PARTE 6 — IMPLEMENTACAO DE AVALIACOES (8:50 - 10:40)

> [abrir router.go, avaliacao_handler.go e avaliacao/service.go]

"No Vinum, avaliacoes tem endpoints publicos e protegidos.

Publicos:

1. GET /v1/wines/{wine_id}/reviews
2. GET /v1/reviews/{id}

Protegidos por JWT:

1. POST /v1/wines/{wine_id}/reviews
2. PATCH /v1/reviews/{id}
3. DELETE /v1/reviews/{id}

Regras principais da feature:

1. Nota precisa estar entre 0 e 10.
2. Usuario autenticado vem do claims.Subject.
3. Apenas o dono pode editar/excluir.
4. Existe unicidade para 1 avaliacao por usuario por vinho.

Ou seja, nao e so CRUD. E CRUD com validacao de entrada, autorizacao e regra de negocio forte."

---

## PARTE 7 — IMPLEMENTACAO DE TAGS: MODELO DE DADOS (10:40 - 12:10)

> [abrir migrations 002 e 003]

"As tags foram implementadas com modelagem relacional:

1. Tabela tags: catalogo de opcoes.
2. Tabela tags_avaliacoes: relacao N para N com avaliacoes.
3. View avaliacoes_with_tags: retorna avaliacao com array de codigos de tag.

Os codigos iniciais sao:
AMADEIRADO, SUAVE, ENCORPADO, FRUTADO, SECO, CITRICO.

Tambem existe indice unico em avaliacoes para garantir 1 avaliacao por usuario por vinho, o que impacta diretamente o fluxo de reviews."

---

## PARTE 8 — IMPLEMENTACAO DE TAGS NO BACKEND (12:10 - 14:20)

> [abrir tag/entity.go, avaliacao/service.go e avaliacao_repository.go]

"A validacao de tags acontece em duas camadas.

Camada Go:

1. NormalizeCodes faz trim + uppercase.
2. Remove duplicadas.
3. Rejeita codigo invalido.

Camada SQL (seguranca adicional):

As funcoes create_avaliacao_with_tags e update_avaliacao_with_tags verificam se todos os codigos enviados existem na tabela tags. Se faltar algum, gera erro invalid tag code.

No create e update, o BFF chama RPC transacional. Resultado: avaliacao e relacao de tags ficam consistentes em uma operacao unica, inclusive quando ha edicao de review."

---

## PARTE 9 — IMPLEMENTACAO DE TAGS NO APP FLUTTER (14:20 - 16:10)

> [abrir review_remote_datasource.dart, review_form_sheet.dart e review_card.dart]

"No app, o fluxo de tags e:

1. Formulario dispara evento para carregar tags.
2. GET /v1/tags retorna code e label.
3. Usuario seleciona badges de tags.
4. No submit, o app envia tags como lista de codigos.

Exemplo de payload:

{
    "nota": 8.5,
    "comentario": "Muito bom",
    "tags": ["FRUTADO", "SECO"]
}

Na exibicao, a review volta com as tags e o app renderiza badges coloridas, com label localizada em pt_BR e en_US.

Aqui vale destacar que a tela de detalhe do vinho ja mostra as avaliacoes ordenadas e destaca a avaliacao do usuario atual para facilitar editar ou excluir."

---

## PARTE 10 — ROTEIRO DE DEMO AO VIVO (16:10 - 18:20)

> [fluxo sugerido para apresentacao]

"Demo em 6 passos:

1. Fazer login com Google.
2. Abrir um vinho e mostrar lista publica de avaliacoes.
3. Mostrar botao de criar avaliacao (so aparece autenticado).
4. Criar review com 2 tags.
5. Editar review trocando tags.
6. Mostrar que apenas o dono consegue editar/excluir a propria review.

Se quiser reforcar seguranca, mostrar rapidamente no backend onde o usuario vem de claims.Subject e nao do body."

---

## FECHAMENTO (18:20 - 19:20)

> [camera]

"Resumo final:

1. JWT protege as rotas sensiveis e identifica usuario pelo subject.
2. Avaliacoes tem regras claras de ownership, validacao e unicidade.
3. O BFF centraliza autenticacao, autorizacao e regra de negocio.
4. Tags foram implementadas com catalogo fixo, relacao N para N e validacao dupla (Go + SQL).
5. O resultado e um fluxo seguro, consistente e pronto para escalar.

No Vinum, autenticacao, avaliacoes e tags nao sao so detalhe de interface, sao parte central da arquitetura de produto."

---

## COLA RAPIDA (PERGUNTAS QUE PODEM CAIR)

1. Por que usar BFF entre app e Supabase?
Para concentrar seguranca, validacao e estabilidade de contrato.

2. Como impedem falsificacao de usuario_id?
O BFF usa claims.Subject do JWT validado no middleware.

3. Como evitam tags invalidas?
Validacao no Go + validacao no SQL das funcoes RPC.

4. Como evitam multiplas reviews da mesma pessoa no mesmo vinho?
Indice unico em (wine_id, usuario_id).

5. O endpoint de tags e protegido?
Nao. GET /v1/tags e publico para facilitar preenchimento do formulario.

6. Quais endpoints de review sao publicos e quais sao protegidos?
Listagem e detalhe sao publicos. Criar, editar e excluir exigem JWT.

---

Duracao estimada: 18 a 20 minutos.
