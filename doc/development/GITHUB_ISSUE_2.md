# Issue 2: Context is not sent to strategies

✅ **Resolvido na v1.4.0!**

O context agora é **automaticamente passado para todas as estratégias**:

## O que foi implementado:

### 1. LogEntry completo
- Todas as estratégias agora recebem um objeto `LogEntry` completo
- Inclui: `level`, `message`, `timestamp`, `context`, `stackTrace`, `event`

### 2. Zero breaking changes
- Estratégias antigas continuam funcionando sem modificação
- Context está disponível automaticamente mesmo em estratégias legacy
- API pública (`logger.log()`) permanece inalterada

### 3. Todas as estratégias atualizadas
- **ConsoleLogStrategy** - Context exibido no console formatado
- **DatadogLogStrategy** - Context incluído nos campos do log para indexação
- **SentryLogStrategy** - Context adicionado como Sentry extra fields
- **FirebaseAnalyticsLogStrategy** - Context como event parameters
- **FirebaseCrashlyticsLogStrategy** - Context como custom keys
- **NewRelicLogStrategy** - Context como log attributes
- E todas as outras estratégias built-in

## Exemplo de uso:

```dart
await logger.log(
  'User action',
  context: {
    'userId': 123,
    'screen': 'home',
    'action': 'button_click',
  },
);
// Context é automaticamente passado para TODAS as estratégias!
```

No Datadog, você pode agora filtrar por esses campos:
```
userId:123 screen:home
```

## Como funciona:

A interface `LogStrategy` foi atualizada para receber `LogEntry` completo, mas mantém **100% de compatibilidade** com estratégias antigas através de default implementations que delegam para métodos legacy.

**Nova forma (recomendada):**
```dart
class MyStrategy extends LogStrategy {
  @override
  Future<void> log(LogEntry entry) async {
    // entry.context está disponível aqui!
    print('Context: ${entry.context}');
  }
}
```

**Forma legacy (ainda funciona):**
```dart
class MyLegacyStrategy extends LogStrategy {
  @override
  Future<void> logMessage(
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context, // ← Context agora disponível!
  ) async {
    print('Context: $context');
  }
}
```

## Documentação
- [BACKWARD_COMPATIBILITY.md](doc/guides/BACKWARD_COMPATIBILITY.md) - Detalhes de compatibilidade
- [CHANGELOG.md](CHANGELOG.md) - Lista completa de mudanças
- [example/legacy_strategy_example.dart](example/legacy_strategy_example.dart) - Exemplo de estratégia legacy

**Versão:** 1.4.0  
**Status:** ✅ Resolvido e publicado
