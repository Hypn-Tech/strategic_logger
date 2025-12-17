# Análise: Como Evitar Breaking Changes

## Situação Atual

- Interface `LogStrategy` tem métodos abstratos que recebem `LogEntry`
- Todas as 8 estratégias built-in já foram atualizadas
- O `_executeStrategy` chama diretamente `strategy.log(entry)`

## Opções para Evitar Breaking Changes

### ✅ Opção 1: Default Implementations com Métodos Auxiliares (RECOMENDADA)

**Como funciona:**
- Transformar métodos abstratos em métodos com implementação padrão
- A implementação padrão chama métodos auxiliares que podem ser sobrescritos
- Manter métodos antigos como deprecated que criam LogEntry e chamam os novos

**Estrutura:**
```dart
abstract class LogStrategy {
  // Métodos novos (com default implementation)
  Future<void> log(LogEntry entry) async {
    // Default: converte para formato antigo e chama método auxiliar
    await logMessage(entry.message, entry.event, entry.context);
  }
  
  Future<void> info(LogEntry entry) async {
    await logMessage(entry.message, entry.event, entry.context);
  }
  
  Future<void> error(LogEntry entry) async {
    await logError(entry.message, entry.stackTrace, entry.event, entry.context);
  }
  
  Future<void> fatal(LogEntry entry) async {
    await logError(entry.message, entry.stackTrace, entry.event, entry.context);
  }
  
  // Métodos auxiliares (podem ser sobrescritos por estratégias antigas)
  @protected
  Future<void> logMessage(dynamic message, LogEvent? event, Map<String, dynamic>? context) async {
    // Implementação padrão vazia - estratégias antigas sobrescrevem isso
  }
  
  @protected
  Future<void> logError(dynamic error, StackTrace? stackTrace, LogEvent? event, Map<String, dynamic>? context) async {
    // Implementação padrão vazia - estratégias antigas sobrescrevem isso
  }
  
  // Métodos antigos (deprecated, mas funcionam)
  @Deprecated('Use log(LogEntry) instead. Will be removed in v2.0.0')
  Future<void> logLegacy({dynamic message, LogEvent? event}) async {
    final entry = LogEntry.fromParams(
      message: message ?? '',
      level: LogLevel.info,
      event: event,
    );
    await log(entry);
  }
}
```

**Vantagens:**
- ✅ Zero breaking changes - estratégias antigas continuam funcionando
- ✅ Estratégias novas podem usar diretamente `log(LogEntry)`
- ✅ Estratégias antigas podem migrar gradualmente
- ✅ Context passa a funcionar mesmo em estratégias antigas (via LogEntry)

**Desvantagens:**
- ⚠️ Código mais complexo (mas gerenciável)
- ⚠️ Métodos deprecated precisam ser mantidos até v2.0.0

**Implementação:**
- Estratégias antigas sobrescrevem `logMessage()` e `logError()`
- Estratégias novas sobrescrevem `log()`, `info()`, `error()`, `fatal()`
- O `_executeStrategy` sempre chama os métodos novos (`log(entry)`)

---

### Opção 2: Adapter Pattern com Detecção de Tipo

**Como funciona:**
- Criar um wrapper que detecta se a estratégia implementa método antigo ou novo
- Usar reflection ou try-catch para detectar qual interface usar

**Estrutura:**
```dart
class LogStrategyAdapter {
  static Future<void> execute(LogStrategy strategy, LogEntry entry) async {
    // Tenta chamar método novo
    try {
      await strategy.log(entry);
    } catch (e) {
      // Se falhar, tenta método antigo
      await strategy.logLegacy(message: entry.message, event: entry.event);
    }
  }
}
```

**Vantagens:**
- ✅ Permite ambas as interfaces coexistirem

**Desvantagens:**
- ❌ Reflection não é ideal em Dart
- ❌ Try-catch para controle de fluxo é anti-pattern
- ❌ Performance impact
- ❌ Complexidade alta

---

### Opção 3: Interface Separada (LogStrategyV2)

**Como funciona:**
- Criar `LogStrategyV2` com métodos novos
- Manter `LogStrategy` com métodos antigos
- Fazer estratégias built-in implementarem ambas

**Estrutura:**
```dart
abstract class LogStrategy {
  Future<void> log({dynamic message, LogEvent? event});
  // ... métodos antigos
}

abstract class LogStrategyV2 extends LogStrategy {
  Future<void> logV2(LogEntry entry);
  // ... métodos novos
}
```

**Vantagens:**
- ✅ Separação clara entre versões

**Desvantagens:**
- ❌ Estratégias precisam implementar ambas interfaces
- ❌ Duplicação de código
- ❌ Ainda há breaking change para quem quer usar V2

---

### Opção 4: Named Parameters Opcionais

**Como funciona:**
- Manter métodos antigos, mas adicionar parâmetro `LogEntry?` opcional
- Se `LogEntry` for fornecido, usar ele; senão, usar parâmetros individuais

**Estrutura:**
```dart
abstract class LogStrategy {
  Future<void> log({
    dynamic message,
    LogEvent? event,
    LogEntry? entry,  // Novo parâmetro opcional
  }) async {
    if (entry != null) {
      // Usar entry (nova forma)
      await logEntry(entry);
    } else {
      // Usar parâmetros individuais (forma antiga)
      await logMessage(message, event);
    }
  }
}
```

**Vantagens:**
- ✅ Uma única interface
- ✅ Compatibilidade total

**Desvantagens:**
- ❌ Interface confusa (muitos parâmetros)
- ❌ Não resolve o problema - ainda precisa passar context separadamente
- ❌ Estratégias antigas não receberiam context automaticamente

---

## 🎯 Recomendação: Opção 1 (Default Implementations)

### Por quê?

1. **Zero Breaking Changes**: Estratégias antigas continuam funcionando sem modificação
2. **Context Funciona**: Mesmo estratégias antigas recebem context via LogEntry
3. **Migração Gradual**: Estratégias podem migrar quando quiserem
4. **Código Limpo**: Estratégias novas usam interface limpa
5. **Deprecation Path**: Métodos antigos podem ser removidos em v2.0.0

### Implementação Proposta

```dart
abstract class LogStrategy {
  // Métodos principais (recebem LogEntry)
  Future<void> log(LogEntry entry) async {
    await logMessage(entry.message, entry.event, entry.context);
  }
  
  Future<void> info(LogEntry entry) async {
    await logMessage(entry.message, entry.event, entry.context);
  }
  
  Future<void> error(LogEntry entry) async {
    await logError(entry.message, entry.stackTrace, entry.event, entry.context);
  }
  
  Future<void> fatal(LogEntry entry) async {
    await logError(entry.message, entry.stackTrace, entry.event, entry.context);
  }
  
  // Métodos auxiliares (para compatibilidade com estratégias antigas)
  @protected
  Future<void> logMessage(
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context,
  ) async {
    // Default: vazio - estratégias antigas sobrescrevem
  }
  
  @protected
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context,
  ) async {
    // Default: vazio - estratégias antigas sobrescrevem
  }
}
```

### Como Funciona

1. **Estratégias Antigas (customizadas):**
   - Sobrescrevem `logMessage()` e `logError()`
   - Recebem `context` como parâmetro (novo!)
   - Continuam funcionando sem mudanças

2. **Estratégias Novas (built-in):**
   - Sobrescrevem `log()`, `info()`, `error()`, `fatal()`
   - Recebem `LogEntry` completo
   - Usam interface limpa

3. **Logger (`_executeStrategy`):**
   - Sempre chama `strategy.log(entry)`
   - O método `log()` internamente chama `logMessage()` com context
   - Estratégias antigas recebem context automaticamente!

### Exemplo: Estratégia Antiga Funcionando

```dart
// Estratégia antiga (sem mudanças necessárias!)
class MyOldStrategy extends LogStrategy {
  @override
  Future<void> logMessage(dynamic message, LogEvent? event, Map<String, dynamic>? context) async {
    // Agora recebe context automaticamente! 🎉
    print('Message: $message');
    if (context != null) {
      print('Context: $context');  // Context funciona!
    }
  }
  
  @override
  Future<void> logError(dynamic error, StackTrace? stackTrace, LogEvent? event, Map<String, dynamic>? context) async {
    print('Error: $error');
    if (context != null) {
      print('Context: $context');  // Context funciona!
    }
  }
}
```

## Conclusão

A **Opção 1** é a melhor porque:
- ✅ Elimina breaking changes completamente
- ✅ Context funciona automaticamente em todas as estratégias
- ✅ Permite migração gradual
- ✅ Mantém código limpo para estratégias novas
- ✅ Fornece path claro de deprecation

**Próximos Passos:**
1. Implementar Opção 1
2. Atualizar estratégias built-in para usar métodos novos diretamente
3. Manter compatibilidade com estratégias antigas
4. Documentar que estratégias antigas agora recebem context automaticamente
