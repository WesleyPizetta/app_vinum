# app_vinum

App Flutter para o projeto **Vinum**, com autenticação via Google (Supabase) e integração com a [api-vinum-bff](https://github.com/WesleyPizetta/api-vinum-bff).

## Link apresentação YouTube

- [Apresentação projeto](https://youtu.be/RMKR6w7dDE4)

- [Repositório da API](https://github.com/WesleyPizetta/api-vinum-bff)

- [Desenvolvimento backend](https://youtu.be/eFaQLXIUD0c)
Jhonatan Ferreira Bandiera, 
Wesley Marques Pizetta

- [Desenvolvimento da geração de Avatar](https://youtu.be/nx5z_KUrCC0)
Jhonatan Ferreira Bandiera, 
Wesley Marques Pizetta
---

## Pré-requisitos

- [Flutter 3.x+](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (já incluso no Flutter)
- Conta no [Supabase](https://supabase.com/) com Google OAuth configurado
- Projeto no [Google Cloud Console](https://console.cloud.google.com/) com OAuth 2.0 configurado
- [api-vinum-bff](https://github.com/WesleyPizetta/api-vinum-bff) rodando localmente

---

## Setup local

### 1. Clone o repositório

```bash
git clone https://github.com/WesleyPizetta/app_vinum.git
cd app_vinum
git checkout develop
```

### 2. Configure as variáveis de ambiente

Copie o arquivo de exemplo e preencha com os valores reais:

```bash
# Linux/macOS
cp .env.example .env

# Windows
copy .env.example .env
```

Preencha os campos do `.env`:

| Variável | Onde encontrar |
|---|---|
| `SUPABASE_URL` | Supabase Dashboard → Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Settings → API → `anon` `public` |
| `BFF_API_URL` | URL do BFF local (ver tabela abaixo) |
| `GOOGLE_WEB_CLIENT_ID` | Google Cloud Console → Credenciais → OAuth 2.0 → tipo **Aplicativo Web** |
| `GOOGLE_IOS_CLIENT_ID` | Google Cloud Console → Credenciais → OAuth 2.0 → tipo **iOS** |
| `GOOGLE_ANDROID_CLIENT_ID` | Google Cloud Console → Credenciais → OAuth 2.0 → tipo **Android** |

**Valores de `BFF_API_URL` por ambiente:**

| Ambiente | Valor |
|---|---|
| Emulador Android | `http://10.0.2.2:8080` |
| Dispositivo físico | `http://<IP_DA_SUA_MAQUINA>:8080` |
| iOS Simulator | `http://localhost:8080` |

> **Importante:** o arquivo `.env` está no `.gitignore` e **nunca deve ser commitado**.

### 3. Configure o Google Sign-In no Android

Copie o arquivo de exemplo e preencha com o `GOOGLE_WEB_CLIENT_ID`:

```bash
# Linux/macOS
cp android/app/src/main/res/values/strings.xml.example \
   android/app/src/main/res/values/strings.xml

# Windows
copy android\app\src\main\res\values\strings.xml.example ^
     android\app\src\main\res\values\strings.xml
```

Abra o arquivo e substitua `<SEU_WEB_CLIENT_ID>` pelo mesmo valor de `GOOGLE_WEB_CLIENT_ID` do `.env`.

> `strings.xml` está no `.gitignore` e **nunca deve ser commitado**.

### 4. Instale as dependências

```bash
flutter pub get
```

### 5. Cadastre o SHA-1 do seu debug keystore no Google Cloud Console

O Google Sign-In no Android valida a assinatura do app. Em desenvolvimento, cada máquina tem um **debug keystore próprio** — o SHA-1 dele precisa ser cadastrado no Google Cloud Console. Sem isso, o botão social retorna erro silencioso.

#### 5.1 Gere o debug keystore (se ainda não existir)

O arquivo `debug.keystore` é criado automaticamente pelo Gradle no **primeiro build Android**. Se ainda não existe na sua máquina, gere-o com:

```bash
flutter build apk --debug
```

> Após o build terminar, o arquivo estará em `%USERPROFILE%\.android\debug.keystore` (Windows) ou `~/.android/debug.keystore` (Linux/macOS).

#### 5.2 Extraia o SHA-1

```powershell
# Windows (PowerShell)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

```bash
# Linux/macOS
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copie o valor exibido na linha `SHA1:`.

#### 5.3 Cadastre no Google Cloud Console

1. Acesse **[Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials**
2. Clique no OAuth 2.0 Client ID do tipo **Android**
3. Em **SHA-1 certificate fingerprints**, clique em **Add fingerprint**
4. Cole o SHA-1 copiado e salve

> Peça ao responsável pelo projeto acesso de editor ao Google Cloud Console caso não tenha permissão.

> **Esse passo é necessário apenas em desenvolvimento.** Em produção, a chave de release tem um SHA-1 único já cadastrado, e os usuários finais não precisam fazer nada.

### 6. Rode o app

```bash
# Emulador ou dispositivo conectado (flavor dev)
flutter run -t lib/main_dev.dart
```

---

## Estrutura do projeto

```
app_vinum/
├── lib/
│   ├── core/          # DI, temas e utilitários globais
│   ├── environment/   # Configuração por ambiente (dev/prod)
│   ├── feature/       # Features por domínio (auth, wine...)
│   ├── main.dart      # Entrypoint (aponta para main_dev.dart)
│   ├── main_dev.dart  # Entrypoint desenvolvimento
│   └── main_prod.dart # Entrypoint produção
├── packages/
│   └── essentials/    # Pacote interno com abstrações compartilhadas
├── android/           # Configurações Android
├── ios/               # Configurações iOS
├── lang/              # Arquivos de internacionalização (i18n)
├── .env.example       # Template de variáveis de ambiente
└── pubspec.yaml       # Dependências do projeto
```

---

## Arquivos sensíveis (não versionados)

| Arquivo | Descrição |
|---|---|
| `.env` | Variáveis de ambiente (Supabase, BFF, Google OAuth) |
| `android/app/src/main/res/values/strings.xml` | Client ID do Google para o SDK Android |
| `ios/Runner/GoogleService-Info.plist` | Configuração do Google Sign-In para iOS |
| `android/app/google-services.json` | Configuração do Firebase |
| `.env.prod` | Variáveis de ambiente de produção |
| `key.properties` / `*.keystore` | Chaves de assinatura Android |

> Nenhum desses arquivos está no repositório. Solicite-os ao responsável pelo projeto via canal seguro (nunca por e-mail ou chat público).

---

## Branches

| Branch | Propósito |
|---|---|
| `main` | Código estável / produção |
| `develop` | Desenvolvimento ativo |

Fluxo: abra PRs de feature branches (`feat/...`) para `develop`. Quando estável, `develop` → `main`.
