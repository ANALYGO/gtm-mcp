const KV_KEY = "server-refresh-token";

export async function readRefreshTokenFromKV(
  kv: KVNamespace,
): Promise<string | null> {
  return kv.get(KV_KEY);
}

export async function writeRefreshTokenToKV(
  kv: KVNamespace,
  refreshToken: string,
): Promise<void> {
  await kv.put(KV_KEY, refreshToken);
}
