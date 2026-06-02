# OAuth 2.0 Setup for GTM MCP Server

The GTM MCP Server uses Google OAuth 2.0 to authenticate users and authorize access to their Google Tag Manager accounts. Before deploying, you must create an OAuth 2.0 Web Application credential in the Google Cloud Console.

---

## Prerequisites

- A Google Cloud Platform project (create one at https://console.cloud.google.com/)
- The Tag Manager API must be enabled for your project
- Your deployment domain (e.g., `gtm-mcp.analygo.co`) must be accessible

---

## Step-by-Step Instructions

### 1. Create a Google Cloud Project (if you don't have one)

1. Go to https://console.cloud.google.com/
2. Click the project dropdown at the top of the page
3. Click **New Project**
4. Enter a name (e.g., "GTM MCP Server")
5. Click **Create**

### 2. Enable the Google Tag Manager API

1. In the Google Cloud Console, navigate to **APIs & Services > Library**
2. Search for "Tag Manager API"
3. Click on **Google Tag Manager API**
4. Click **Enable**

### 3. Configure the OAuth Consent Screen

1. Go to **APIs & Services > OAuth consent screen**
2. Select **External** user type (or Internal if only your organization will use this)
3. Fill in the required fields:
   - **App name**: `GTM MCP Server`
   - **User support email**: Your email address
   - **Developer contact information**: Your email address
4. Click **Save and Continue**
5. On the **Scopes** page, click **Add or Remove Scopes**
6. Add the following scope:
   ```
   https://www.googleapis.com/auth/tagmanager.edit.containers
   ```
   (If you need additional access, you can also add `tagmanager.readonly` and others)
7. Click **Save and Continue**
8. On the **Test users** page, add the email addresses of users who will test the integration
9. Click **Save and Continue**

### 4. Create an OAuth 2.0 Web Application Credential

1. Go to **APIs & Services > Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Set **Application type** to **Web application**
4. Set **Name** to `GTM MCP Server`
5. Under **Authorized JavaScript origins**, add your deployment URL:
   - `https://gtm-mcp.analygo.co` (replace with your actual domain)
   - For local testing: `http://localhost:3000`
6. Under **Authorized redirect URIs**, add:
   - `https://gtm-mcp.analygo.co/callback` (replace with your actual domain)
   - For local testing: `http://localhost:3000/callback`
7. Click **Create**

### 5. Save Your Credentials

After creation, you will see a modal with:

- **Client ID**: A string like `123456789012-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com`
- **Client Secret**: A string like `GOCSPX-xxxxxxxxxxxxxxxxxxxxx`

**Save both values immediately.** You will need them for deployment.

---

## Required Environment Variables

| Variable | Description | Source |
|---|---|---|
| `GOOGLE_CLIENT_ID` | OAuth 2.0 Client ID | Google Cloud Console (step 5) |
| `GOOGLE_CLIENT_SECRET` | OAuth 2.0 Client Secret | Google Cloud Console (step 5) |
| `COOKIE_ENCRYPTION_KEY` | Random string for encrypting session cookies | Generate (see below) |
| `HOSTED_DOMAIN` | (Optional) Restrict to a Google Workspace domain | Your domain |
| `WORKER_HOST` | The public hostname of your deployment | e.g., `gtm-mcp.analygo.co` |

**To generate `COOKIE_ENCRYPTION_KEY`:**

```bash
# Generate a 32-byte hex key
openssl rand -hex 32
```

---

## Scopes Required

The server requests the following Google API scopes during OAuth:

| Scope | Purpose |
|---|---|
| `email` | Identify the authenticated user |
| `profile` | Get the user's display name |
| `tagmanager.manage.accounts` | List and manage GTM accounts |
| `tagmanager.edit.containers` | Read and edit GTM containers |
| `tagmanager.delete.containers` | Delete GTM containers |
| `tagmanager.edit.containerversions` | Create and edit container versions |
| `tagmanager.manage.users` | Manage container user permissions |
| `tagmanager.publish` | Publish container versions |
| `tagmanager.readonly` | Read-only access to GTM data |

If you want to reduce the scope, edit `src/utils/apisHandler.ts` and remove
unneeded scopes from the `scopes` array in the `redirectToGoogle` function.

---

## Deployment

### Local Development

```bash
# Create a .dev.vars file with your credentials
cat > .dev.vars <<EOF
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
COOKIE_ENCRYPTION_KEY=$(openssl rand -hex 32)
WORKER_HOST=localhost:3000
EOF

# Start the server
npx wrangler dev --ip 0.0.0.0 --port 3000 --remote=false --persist-to /tmp/wrangler-data
```

### Docker / Coolify

Set the environment variables in your Coolify dashboard or `.env` file:

```env
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
COOKIE_ENCRYPTION_KEY=your-32-byte-hex-key
HOSTED_DOMAIN=
WORKER_HOST=gtm-mcp.analygo.co
PORT=3000
```

---

## Verifying the Setup

1. Start the server
2. Visit `http://localhost:3000/` (or your deployment URL)
3. Initiate the OAuth flow by connecting via an MCP client (e.g., Claude Desktop):
   ```json
   {
     "mcpServers": {
       "gtm-mcp-server": {
         "command": "npx",
         "args": ["-y", "mcp-remote", "https://gtm-mcp.analygo.co/mcp"]
       }
     }
   }
   ```
4. A browser window should open for Google OAuth login
5. After granting access, the MCP tools should become available

---

## Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `redirect_uri_mismatch` | Redirect URI not added to OAuth client | Add `https://your-domain/callback` to authorized redirect URIs |
| `Invalid Grant` | Authorization code expired or already used | Restart the OAuth flow |
| `Access Denied` | User not in test users list | Add user to test users in OAuth consent screen |
| Session not persisted | No volume mount for `/data` | Ensure `gtm_mcp_data` volume is mounted |
