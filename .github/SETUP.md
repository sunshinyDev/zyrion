# GitHub Actions — Setup

## Secrets necessários

Vá em **Settings → Secrets and variables → Actions → New repository secret**

### Obrigatórios

| Secret | Valor | Como obter |
|--------|-------|------------|
| `GOOGLE_SERVICES_JSON` | Conteúdo do `google-services.json` | Copie o conteúdo do arquivo |
| `FIREBASE_DB_URL` | `https://streamhub-855ab-default-rtdb.firebaseio.com` | Firebase Console → RTDB |
| `FIREBASE_TOKEN` | Token de acesso ao Firebase | Ver abaixo |

### Opcionais (para APK assinado — recomendado para produção)

| Secret | Valor |
|--------|-------|
| `KEYSTORE_BASE64` | Keystore em base64: `base64 -w 0 meu-keystore.jks` |
| `KEYSTORE_PASSWORD` | Senha do keystore |
| `KEY_ALIAS` | Alias da chave |
| `KEY_PASSWORD` | Senha da chave |

Se não configurar o keystore, o APK será assinado com a chave de debug (funciona para instalação manual).

---

## Como obter o FIREBASE_TOKEN

O Firebase RTDB aceita autenticação via **Database Secret** (token legado):

1. Firebase Console → Project Settings → Service Accounts
2. Clique em **Database secrets** (aba)
3. Copie o secret gerado
4. Cole como `FIREBASE_TOKEN` no GitHub

---

## Como publicar uma versão

```bash
# 1. Commit suas mudanças
git add .
git commit -m "feat: nova versão 1.2.0"

# 2. Crie a tag com a versão
git tag v1.2.0

# 3. Push com a tag
git push origin main --tags
```

O GitHub Actions vai:
1. ✅ Buildar o APK release
2. ✅ Criar a GitHub Release com o APK
3. ✅ Atualizar o Firebase com a nova versão
4. ✅ O app detecta automaticamente e mostra o dialog de atualização

---

## Estrutura da versão

- **Tag**: `v1.2.0` → version_name = `1.2.0`, version_code = `120`
- **APK**: `zyrion-play-1.2.0.apk`
- **URL**: `https://github.com/user/repo/releases/download/v1.2.0/zyrion-play-1.2.0.apk`
