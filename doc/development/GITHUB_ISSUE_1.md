# Issue 1: Add compression & change URL for Datadog strategy

✅ **Resolvido na v1.4.0!**

Implementamos todas as melhorias solicitadas:

## 1. Endpoint atualizado para v2
- Mudado de `https://http-intake.logs.datadoghq.com/v1/input` para `https://http-intake.logs.datadoghq.com/api/v2/logs`
- Agora usa o endpoint oficial recomendado pela Datadog

## 2. Compressão gzip adicionada
- Compressão habilitada por padrão (`enableCompression: true`)
- Reduz significativamente o overhead de rede, especialmente em mobile ou alto volume
- Pode ser desabilitada se necessário: `enableCompression: false`

## 3. Formato JSON v2 correto
- Implementado formato batch v2 com todos os campos necessários:
  - `ddsource`, `ddtags`, `hostname`, `message`, `service`, `status`, `timestamp`
- Context é incluído diretamente nos campos do log para indexação e filtragem

## Exemplo de uso:

```dart
DatadogLogStrategy(
  apiKey: 'your-datadog-api-key',
  service: 'my-app',
  env: 'production',
  enableCompression: true, // Gzip compression (default: true)
  tags: 'team:mobile,version:1.4.0',
  // Usa automaticamente: https://http-intake.logs.datadoghq.com/api/v2/logs
)
```

## Documentação
- Veja [CHANGELOG.md](CHANGELOG.md) para detalhes completos
- Veja [README.md](README.md) para exemplos atualizados

**Versão:** 1.4.0  
**Status:** ✅ Resolvido e publicado
