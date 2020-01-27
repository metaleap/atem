const std = @import("std");

pub const String = []const u8;

pub fn In(comptime T: type) type {
    return struct {
        it: T,
        mem: *std.mem.Allocator,
    };
}

pub fn Out(comptime T: type) type {
    return union(enum) {
        ok: T,
        err: ResponseError,
    };
}

pub const ErrorCodes = enum(isize) {
    /// defined by LSP
    RequestCancelled = -32800,

    /// defined by LSP
    ContentModified = -32801,

    /// defined by JSON-RPC
    ParseError = -32700,

    /// defined by JSON-RPC
    InvalidRequest = -32600,

    /// defined by JSON-RPC
    MethodNotFound = -32601,

    /// defined by JSON-RPC
    InvalidParams = -32602,

    /// defined by JSON-RPC
    InternalError = -32603,

    /// defined by JSON-RPC
    serverErrorStart = -32099,

    /// defined by JSON-RPC
    serverErrorEnd = -32000,

    /// defined by JSON-RPC
    ServerNotInitialized = -32002,

    /// defined by JSON-RPC
    UnknownErrorCode = -32001,
};

pub const IntOrString = union(enum) {
    int: isize,
    string: String,
};

// we don't use std.json.Value union here because:
// 1. after a full parse we want to have all the `std.json.Value`s fully
// transformed into only such types owned in this source file.
// 2. we also want to be able to then immediately dealloc whatever
// std.json.Parser alloc'd, while keeping the result data for upcoming processing.
// some of the LSP-prescribed types do contain free-form "JSON `any`-typed"
// fields, these too should be preserved after std.json.Parser is dealloc'd.
// 3. from current union design, every std.json.Value has a sizeOf std.HashMap, a fat struct!
pub const JsonAny = union(enum) {
    string: String,
    boolean: bool,
    int: i64,
    float: f64,
    array: []JsonAny,
    object: ?*std.StringHashMap(JsonAny),
};

pub const NotifyIn = union(enum) {
    __cancelRequest: fn (In(CancelParams)) void,
    initialized: fn (In(InitializedParams)) void,
    exit: fn (In(void)) void,
    workspace_didChangeWorkspaceFolders: fn (In(DidChangeWorkspaceFoldersParams)) void,
    workspace_didChangeConfiguration: fn (In(DidChangeConfigurationParams)) void,
    workspace_didChangeWatchedFiles: fn (In(DidChangeWatchedFilesParams)) void,
    textDocument_didOpen: fn (In(DidOpenTextDocumentParams)) void,
    textDocument_didChange: fn (In(DidChangeTextDocumentParams)) void,
    textDocument_willSave: fn (In(WillSaveTextDocumentParams)) void,
    textDocument_didSave: fn (In(DidSaveTextDocumentParams)) void,
    textDocument_didClose: fn (In(DidCloseTextDocumentParams)) void,
};

pub const NotifyOut = union(enum) {
    __progress: *ProgressParams,
    window_showMessage: *ShowMessageParams,
    window_logMessage: *LogMessageParams,
    telemetry_event: *JsonAny,
    textDocument_publishDiagnostics: *PublishDiagnosticsParams,
};

pub const RequestIn = union(enum) {
    initialize: fn (In(InitializeParams)) Out(InitializeResult),
    shutdown: fn (In(void)) Out(void),
    workspace_symbol: fn (In(WorkspaceSymbolParams)) Out(?[]SymbolInformation),
    workspace_executeCommand: fn (In(ExecuteCommandParams)) Out(?JsonAny),
    textDocument_willSaveWaitUntil: fn (In(WillSaveTextDocumentParams)) Out(?[]TextEdit),
    textDocument_completion: fn (In(CompletionParams)) Out(?CompletionList),
    completionItem_resolve: fn (In(CompletionItem)) Out(CompletionItem),
    textDocument_hover: fn (In(HoverParams)) Out(?Hover),
    textDocument_signatureHelp: fn (In(SignatureHelpParams)) Out(?SignatureHelp),
    textDocument_declaration: fn (In(DeclarationParams)) Out(?union(enum) {
        locations: []Location,
        links: []LocationLink,
    }),
    textDocument_definition: fn (In(DefinitionParams)) Out(?union(enum) {
        locations: []Location,
        links: []LocationLink,
    }),
    textDocument_typeDefinition: fn (In(TypeDefinitionParams)) Out(?union(enum) {
        locations: []Location,
        links: []LocationLink,
    }),
    textDocument_implementation: fn (In(ImplementationParams)) Out(?union(enum) {
        locations: []Location,
        links: []LocationLink,
    }),
    textDocument_references: fn (In(ReferenceParams)) Out(?[]Location),
    textDocument_documentHighlight: fn (In(DocumentHighlightParams)) Out(?[]DocumentHighlight),
    textDocument_documentSymbol: fn (In(DocumentSymbolParams)) Out(?union(enum) {
        flat: []SymbolInformation,
        hierarchy: []DocumentSymbol,
    }),
    textDocument_codeAction: fn (In(CodeActionParams)) Out(?[]union(enum) {
        code_action: CodeAction,
        command: Command,
    }),
    textDocument_codeLens: fn (In(CodeLensParams)) Out(?[]CodeLens),
    codeLens_resolve: fn (In(CodeLens)) Out(CodeLens),
    textDocument_documentLink: fn (In(DocumentLinkParams)) Out(?[]DocumentLink),
    documentLink_resolve: fn (In(DocumentLink)) Out(DocumentLink),
    textDocument_documentColor: fn (In(DocumentColorParams)) Out([]ColorInformation),
    textDocument_colorPresentation: fn (In(ColorPresentationParams)) Out([]ColorPresentation),
    textDocument_formatting: fn (In(DocumentFormattingParams)) Out(?[]TextEdit),
    textDocument_rangeFormatting: fn (In(DocumentRangeFormattingParams)) Out(?[]TextEdit),
    textDocument_onTypeFormatting: fn (In(DocumentOnTypeFormattingParams)) Out(?[]TextEdit),
    textDocument_rename: fn (In(RenameParams)) Out(?[]WorkspaceEdit),
    textDocument_prepareRename: fn (In(TextDocumentPositionParams)) Out(?Range),
    textDocument_foldingRange: fn (In(FoldingRangeParams)) Out(?[]FoldingRange),
    textDocument_selectionRange: fn (In(SelectionRangeParams)) Out(?[]SelectionRange),
};

pub const RequestOut = union(enum) {
    window_showMessageRequest: *ShowMessageRequestParams,
    window_workDoneProgress_create: *WorkDoneProgressCreateParams,
    client_registerCapability: *RegistrationParams,
    client_unregisterCapability: *UnregistrationParams,
    workspace_workspaceFolders,
    workspace_configuration: *ConfigurationParams,
    workspace_applyEdit: *ApplyWorkspaceEditParams,
};

pub const ResponseIn = union(enum) {
    window_showMessageRequest: fn (?*MessageActionItem) void,
    window_workDoneProgress_create: fn () void,
    client_registerCapability: fn () void,
    client_unregisterCapability: fn () void,
    workspace_workspaceFolders: fn (?[]WorkspaceFolder) void,
    workspace_configuration: fn ([]JsonAny) void,
    workspace_applyEdit: fn (*ApplyWorkspaceEditResponse) void,
};

pub const ResponseOut = union(enum) {
    initialize: *InitializeResult,
    shutdown,
    workspace_symbol: ?[]SymbolInformation,
    workspace_executeCommand: ?*JsonAny,
    textDocument_willSaveWaitUntil: ?[]TextEdit,
    textDocument_completion: ?*CompletionList,
    completionItem_resolve: *CompletionItem,
    textDocument_hover: ?*Hover,
    textDocument_signatureHelp: ?*SignatureHelp,
    textDocument_declaration: ?union(enum) {
        locations: []Location,
        links: []LocationLink,
    },
    textDocument_definition: ?union(enum) {
        locations: []Location,
        links: []LocationLink,
    },
    textDocument_typeDefinition: ?union(enum) {
        locations: []Location,
        links: []LocationLink,
    },
    textDocument_implementation: ?union(enum) {
        locations: []Location,
        links: []LocationLink,
    },
    textDocument_references: ?[]Location,
    textDocument_documentHighlight: ?[]DocumentHighlight,
    textDocument_documentSymbol: ?union(enum) {
        flat: []SymbolInformation,
        hierarchy: []DocumentSymbol,
    },
    textDocument_codeAction: ?[]union(enum) {
        code_action: CodeAction,
        command: Command,
    },
    textDocument_codeLens: ?[]CodeLens,
    codeLens_resolve: *CodeLens,
    textDocument_documentLink: ?[]DocumentLink,
    documentLink_resolve: *DocumentLink,
    textDocument_documentColor: []ColorInformation,
    textDocument_colorPresentation: []ColorPresentation,
    textDocument_formatting: ?[]TextEdit,
    textDocument_rangeFormatting: ?[]TextEdit,
    textDocument_onTypeFormatting: ?[]TextEdit,
    textDocument_rename: ?[]WorkspaceEdit,
    textDocument_prepareRename: ?*Range,
    textDocument_foldingRange: ?[]FoldingRange,
    textDocument_selectionRange: ?[]SelectionRange,
};

pub const ResponseError = struct {
    /// see `ErrorCodes` enumeration
    code: isize,
    message: String,
    data: ?JsonAny,
};

pub const CancelParams = struct {
    id: IntOrString,
};

pub const DocumentUri = String;

pub const Position = struct {
    line: isize,
    character: isize,
};

pub const Range = struct {
    start: Position,
    end: Position,
};

pub const Location = struct {
    uri: DocumentUri,
    range: Range,
};

pub const LocationLink = struct {
    originSelectionRange: ?Range,
    targetUri: DocumentUri,
    targetRange: Range,
    targetSelectionRange: Range,
};

pub const Diagnostic = struct {
    range: Range,
    severity: ?enum {
        __ = 0,
        Error = 1,
        Warning = 2,
        Information = 3,
        Hint = 4,
    },
    code: ?IntOrString,
    source: ?String,
    message: String,
    tags: ?[]DiagnosticTag,
    relatedInformation: ?[]DiagnosticRelatedInformation,
};

pub const DiagnosticTag = enum {
    __ = 0,
    Unnecessary = 1,
    Deprecated = 2,
};

pub const DiagnosticRelatedInformation = struct {
    location: Location,
    message: String,
};

pub const Command = struct {
    title: String,
    command: String,
    arguments: ?[]JsonAny,
};

pub const TextEdit = struct {
    range: Range,
    newText: String,
};

pub const TextDocumentEdit = struct {
    textDocument: VersionedTextDocumentIdentifier,
    edits: []TextEdit,
};

pub const VersionedTextDocumentIdentifier = struct {
    TextDocumentIdentifier: TextDocumentIdentifier,
    version: ?isize,
};

pub const TextDocumentPositionParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
};

pub const TextDocumentIdentifier = struct {
    uri: DocumentUri,
};

pub const WorkspaceEdit = struct {
    changes: ?std.StringHashMap([]TextEdit), // ?std.AutoHashMap(DocumentUri, []TextEdit),
    documentChanges: ?[]union(enum) {
        edit: TextDocumentEdit,
        file_create: struct {
            kind: String = "create",
            uri: DocumentUri,
            options: ?struct {
                overwrite: ?bool,
                ignoreIfExists: ?bool,
            } = null,
        },
        file_rename: struct {
            kind: String = "rename",
            oldUri: DocumentUri,
            newUri: DocumentUri,
            options: ?struct {
                overwrite: ?bool,
                ignoreIfExists: ?bool,
            } = null,
        },
        file_delete: struct {
            kind: String = "delete",
            uri: DocumentUri,
            options: ?struct {
                recursive: ?bool,
                ignoreIfNotExists: ?bool,
            } = null,
        },
    },
};

pub const TextDocumentItem = struct {
    uri: DocumentUri,
    languageId: String,
    version: isize,
    text: String,
};

pub const DocumentFilter = struct {
    language: ?String,
    scheme: ?String,
    pattern: ?String,
};

pub const DocumentSelector = []DocumentFilter;

pub const MarkupContent = struct {
    kind: String,
    value: String,

    pub const kind = struct {
        pub const plaintext = "plaintext";
        pub const markdown = "markdown";
    };
};

pub const InitializeParams = struct {
    processId: ?isize,
    clientInfo: ?struct {
        name: String,
        version: ?String,
    },
    rootUri: ?DocumentUri,
    initializationOptions: ?JsonAny,
    capabilities: ClientCapabilities,
    trace: ?String,
    workspaceFolders: ?[]WorkspaceFolder,

    pub const trace_off = "off";
    pub const trace_messages = "messages";
    pub const trace_verbose = "verbose";
};

pub const code_action_kind = struct {
    pub const quickfix = "quickfix";
    pub const refactor = "refactor";
    pub const refactor_extract = "refactor.extract";
    pub const refactor_inline = "refactor.inline";
    pub const refactor_rewrite = "refactor.rewrite";
    pub const source = "source";
    pub const source_organizeImports = "source.organizeImports";
};

pub const CompletionItemTag = enum {
    __ = 0,
    Deprecated = 1,
};

pub const CompletionItemKind = enum {
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Class = 7,
    Interface = 8,
    Module = 9,
    Property = 10,
    Unit = 11,
    Value = 12,
    Enum = 13,
    Keyword = 14,
    Snippet = 15,
    Color = 16,
    File = 17,
    Reference = 18,
    Folder = 19,
    EnumMember = 20,
    Constant = 21,
    Struct = 22,
    Event = 23,
    Operator = 24,
    TypeParameter = 25,
};

pub const SymbolKind = enum {
    File = 1,
    Module = 2,
    Namespace = 3,
    Package = 4,
    Class = 5,
    Method = 6,
    Property = 7,
    Field = 8,
    Constructor = 9,
    Enum = 10,
    Interface = 11,
    Function = 12,
    Variable = 13,
    Constant = 14,
    String = 15,
    Number = 16,
    Boolean = 17,
    Array = 18,
    Object = 19,
    Key = 20,
    Null = 21,
    EnumMember = 22,
    Struct = 23,
    Event = 24,
    Operator = 25,
    TypeParameter = 26,
};

pub const ClientCapabilities = struct {
    workspace: ?struct {
        applyEdit: ?bool,
        workspaceEdit: ?struct {
            documentChanges: ?bool,
            resourceOperations: ?[]String,
            failureHandling: ?String,

            pub const resource_operation_kind_create = "create";
            pub const resource_operation_kind_rename = "rename";
            pub const resource_operation_kind_delete = "delete";
            pub const failure_handling_kind_abort = "abort";
            pub const failure_handling_kind_transactional = "transactional";
            pub const failure_handling_kind_undo = "undo";
            pub const failure_handling_kind_textOnlyTransactional = "textOnlyTransactional";
        },
        didChangeConfiguration: ?struct {
            dynamicRegistration: ?bool,
        },
        didChangeWatchedFiles: ?struct {
            dynamicRegistration: ?bool,
        },
        symbol: ?struct {
            dynamicRegistration: ?bool,
            symbolKind: ?struct {
                valueSet: ?[]SymbolKind,
            },
        },
        executeCommand: ?struct {
            dynamicRegistration: ?bool,
        },
        workspaceFolders: ?bool,
        configuration: ?bool,
    },
    textDocument: ?struct {
        selectionRange: ?struct {
            dynamicRegistration: ?bool,
        },
        synchronization: ?struct {
            dynamicRegistration: ?bool,
            willSave: ?bool,
            willSaveWaitUntil: ?bool,
            didSave: ?bool,
        },
        completion: ?struct {
            dynamicRegistration: ?bool,
            completionItem: ?struct {
                snippetSupport: ?bool,
                commitCharactersSupport: ?bool,
                documentationFormat: ?[]String,
                deprecatedSupport: ?bool,
                preselectSupport: ?bool,
                tagSupport: ?struct {
                    valueSet: ?[]CompletionItemTag,
                },
            },
            completionItemKind: ?struct {
                valueSet: ?[]CompletionItemKind,
            },
            contextSupport: ?bool,
        },
        hover: ?struct {
            dynamicRegistration: ?bool,
            contentFormat: ?[]String,
        },
        signatureHelp: ?struct {
            dynamicRegistration: ?bool,
            signatureInformation: ?struct {
                documentationFormat: ?[]String,
                parameterInformation: ?struct {
                    labelOffsetSupport: ?bool,
                },
            },
            contextSupport: ?bool,
        },
        references: ?struct {
            dynamicRegistration: ?bool,
        },
        documentHighlight: ?struct {
            dynamicRegistration: ?bool,
        },
        documentSymbol: ?struct {
            dynamicRegistration: ?bool,
            symbolKind: ?struct {
                valueSet: ?[]SymbolKind,
            },
            hierarchicalDocumentSymbolSupport: ?bool,
        },
        formatting: ?struct {
            dynamicRegistration: ?bool,
        },
        rangeFormatting: ?struct {
            dynamicRegistration: ?bool,
        },
        onTypeFormatting: ?struct {
            dynamicRegistration: ?bool,
        },
        declaration: ?struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        },
        definition: ?struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        },
        typeDefinition: ?struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        },
        implementation: ?struct {
            dynamicRegistration: ?bool,
            linkSupport: ?bool,
        },
        codeAction: ?struct {
            dynamicRegistration: ?bool,
            codeActionLiteralSupport: ?struct {
                codeActionKind: struct {
                    valueSet: []String,
                },
            },
            isPreferredSupport: ?bool,
        },
        codeLens: ?struct {
            dynamicRegistration: ?bool,
        },
        documentLink: ?struct {
            dynamicRegistration: ?bool,
            tooltipSupport: ?bool,
        },
        colorProvider: ?struct {
            dynamicRegistration: ?bool,
        },
        rename: ?struct {
            dynamicRegistration: ?bool,
            prepareSupport: ?bool,
        },
        publishDiagnostics: ?struct {
            relatedInformation: ?bool,
            tagSupport: ?struct {
                valueSet: []DiagnosticTag,
            },
            versionSupport: ?bool,
        },
        foldingRange: ?struct {
            dynamicRegistration: ?bool,
            rangeLimit: ?bool,
            lineFoldingOnly: ?bool,
        },
    },
    experimental: ?JsonAny,
};

pub const InitializeResult = struct {
    capabilities: ServerCapabilities,
    serverInfo: ?struct {
        name: String,
        version: ?String = null,
    } = null,
};

pub const TextDocumentSyncKind = enum {
    None = 0,
    Full = 1,
    Incremental = 2,
};

pub const CompletionOptions = struct {
    resolveProvider: ?bool,
    triggerCharacters: ?[]String,
};

pub const SignatureHelpOptions = struct {
    triggerCharacters: ?[]String,
    retriggerCharacters: ?[]String,
};

pub const CodeActionOptions = struct {
    codeActionKinds: ?[]String,
};

pub const CodeLensOptions = struct {
    resolveProvider: ?bool,
};

pub const DocumentOnTypeFormattingOptions = struct {
    firstTriggerCharacter: String,
    moreTriggerCharacter: ?[]String,
};

pub const RenameOptions = struct {
    prepareProvider: ?bool,
};

pub const DocumentLinkOptions = struct {
    resolveProvider: ?bool,
};

pub const ExecuteCommandOptions = struct {
    commands: []String,
};

pub const SaveOptions = struct {
    includeText: ?bool,
};

pub const TextDocumentSyncOptions = struct {
    openClose: ?bool,
    change: ?isize,
    willSave: ?bool,
    willSaveWaitUntil: ?bool,
    save: ?SaveOptions,
};

pub const StaticRegistrationOptions = struct {
    id: ?string,
};

pub const ServerCapabilities = struct {
    textDocumentSync: ?TextDocumentSyncOptions = null,
    hoverProvider: ?bool = null,
    completionProvider: ?CompletionOptions = null,
    signatureHelpProvider: ?SignatureHelpOptions = null,
    definitionProvider: ?bool = null,
    typeDefinitionProvider: ?bool = null,
    implementationProvider: ?bool = null,
    referencesProvider: ?bool = null,
    documentHighlightProvider: ?bool = null,
    documentSymbolProvider: ?bool = null,
    workspaceSymbolProvider: ?bool = null,
    codeActionProvider: ?bool = null,
    codeLensProvider: ?CodeLensOptions = null,
    documentFormattingProvider: ?bool = null,
    documentRangeFormattingProvider: ?bool = null,
    documentOnTypeFormattingProvider: ?DocumentOnTypeFormattingOptions = null,
    renameProvider: ?bool = null,
    documentLinkProvider: ?DocumentLinkOptions = null,
    colorProvider: ?bool = null,
    foldingRangeProvider: ?bool = null,
    declarationProvider: ?bool = null,
    executeCommandProvider: ?ExecuteCommandOptions = null,
    workspace: ?struct {
        workspaceFolders: ?struct {
            supported: ?bool = null,
            changeNotifications: ?bool = null,
        } = null,
    } = null,
    selectionRangeProvider: ?bool = null,
    experimental: ?JsonAny = null,
};

pub const InitializedParams = struct {};

pub const ShowMessageParams = struct {
    type__: MessageType,
    message: String,
};

pub const MessageType = enum {
    Error = 1,
    Warning = 2,
    Info = 3,
    Log = 4,
};

pub const ShowMessageRequestParams = struct {
    type__: MessageType,
    message: String,
    actions: ?[]MessageActionItem,
};

pub const MessageActionItem = struct {
    title: String,
};

pub const LogMessageParams = struct {
    type__: MessageType,
    message: String,
};

pub const Registration = struct {
    id: String,
    method: String,
    registerOptions: ?JsonAny,
};

pub const RegistrationParams = struct {
    registrations: []Registration,
};

pub const TextDocumentRegistrationOptions = struct {
    documentSelector: ?DocumentSelector,
};

pub const Unregistration = struct {
    id: String,
    method: String,
};

pub const UnregistrationParams = struct {
    unregisterations: []Unregistration,
};

pub const WorkspaceFolder = struct {
    uri: DocumentUri,
    name: String,
};

pub const DidChangeWorkspaceFoldersParams = struct {
    event: WorkspaceFoldersChangeEvent,
};

pub const WorkspaceFoldersChangeEvent = struct {
    added: []WorkspaceFolder,
    removded: []WorkspaceFolder,
};

pub const DidChangeConfigurationParams = struct {
    settings: JsonAny,
};

pub const ConfigurationParams = struct {
    items: []ConfigurationItem,
};

pub const ConfigurationItem = struct {
    scopeUri: ?DocumentUri,
    section: ?String,
};

pub const DidChangeWatchedFilesParams = struct {
    changes: []FileEvent,
};

pub const FileEvent = struct {
    uri: DocumentUri,
    type__: enum {
        __ = 0,
        Created = 1,
        Changed = 2,
        Deleted = 3,
    },
};

pub const DidChangeWatchedFilesRegistrationOptions = struct {
    watchers: []FileSystemWatcher,
};

pub const FileSystemWatcher = struct {
    globPattern: String,
    kind: ?enum {
        Created = 1,
        Changed = 2,
        Deleted = 3,
    },
};

pub const WorkspaceSymbolParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    query: String,
};

pub const ExecuteCommandParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    command: String,
    arguments: ?[]JsonAny,
};

pub const ExecuteCommandRegistrationOptions = struct {
    commands: []String,
};

pub const ApplyWorkspaceEditParams = struct {
    label: ?String,
    edit: WorkspaceEdit,
};

pub const ApplyWorkspaceEditResponse = struct {
    applied: bool,
    failureReason: ?String,
};

pub const DidOpenTextDocumentParams = struct {
    textDocument: TextDocumentItem,
};

pub const DidChangeTextDocumentParams = struct {
    textDocument: VersionedTextDocumentIdentifier,
    contentChanges: []TextDocumentContentChangeEvent,
};

pub const TextDocumentContentChangeEvent = struct {
    range: ?Range,
    rangeLength: ?isize,
    text: String,
};

pub const TextDocumentChangeRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    syncKind: TextDocumentSyncKind,
};

pub const WillSaveTextDocumentParams = struct {
    textDocument: TextDocumentIdentifier,
    reason: ?enum {
        Manual = 1,
        AfterDelay = 2,
        FocusOut = 3,
    },
};

pub const DidSaveTextDocumentParams = struct {
    textDocument: TextDocumentIdentifier,
    text: ?String,
};

pub const TextDocumentSaveRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    includeText: ?bool,
};

pub const DidCloseTextDocumentParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const PublishDiagnosticsParams = struct {
    uri: DocumentUri,
    version: ?isize,
    diagnostics: []Diagnostic,
};

pub const CompletionParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    context: ?CompletionContext,
};

pub const CompletionTriggerKind = enum {
    Invoked = 1,
    TriggerCharacter = 2,
    TriggerForIncompleteCompletions = 3,
};

pub const CompletionContext = struct {
    triggerKind: ?CompletionTriggerKind,
    triggerCharacter: ?String,
};

pub const CompletionList = struct {
    isIncomplete: bool,
    items: []CompletionItem,
};

pub const InsertTextFormat = enum {
    __ = 0,
    PlainText = 1,
    Snippet = 2,
};

pub const CompletionItem = struct {
    label: String,
    kind: ?CompletionItemKind,
    tags: ?[]CompletionItemTag,
    detail: ?String,
    documentation: ?MarkupContent,
    deprecated: ?bool,
    preselect: ?bool,
    sortText: ?String,
    filterText: ?String,
    insertText: ?String,
    insertTextFormat: ?InsertTextFormat,
    textEdit: ?TextEdit,
    additionalTextEdits: ?[]TextEdit,
    commitCharacters: ?[]String,
    command: ?String,
    data: ?JsonAny,
};

pub const CompletionRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    triggerCharacters: ?[]String,
    allCommitCharacters: ?[]String,
    resolveProvider: ?bool,
};

pub const Hover = struct {
    contents: MarkupContent,
    range: ?Range,
};

pub const SignatureHelp = struct {
    signatures: []SignatureInformation,
    activeSignature: ?isize,
    activeParameter: ?isize,
};

pub const SignatureInformation = struct {
    label: String,
    documentation: ?MarkupContent,
    parameters: ?[]ParameterInformation,
};

pub const ParameterInformation = struct {
    label: String,
    documentation: ?MarkupContent,
};

pub const SignatureHelpRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    triggerCharacters: ?[]String,
};

pub const ReferenceParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    context: ReferenceContext,
};

pub const ReferenceContext = struct {
    includeDeclaration: bool,
};

pub const DocumentHighlight = struct {
    range: Range,
    kind: ?enum {
        Text = 1,
        Read = 2,
        Write = 3,
    },
};

pub const DocumentSymbolParams = struct {
    textDocument: TextDocumentIdentifier,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const DocumentSymbol = struct {
    name: String,
    detail: ?String,
    kind: SymbolKind,
    deprecated: ?bool,
    range: Range,
    selectionRange: Range,
    children: ?[]DocumentSymbol,
};

pub const SymbolInformation = struct {
    name: String,
    kind: SymbolKind,
    deprecated: ?bool,
    location: Location,
    containerName: ?String,
};

pub const CodeActionParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    textDocument: TextDocumentIdentifier,
    range: Range,
    context: CodeActionContext,
};

pub const CodeActionContext = struct {
    diagnostics: []Diagnostic,
    only: ?[]String,
};

pub const CodeAction = struct {
    title: String,
    kind: ?String,
    diagnostics: ?[]Diagnostic,
    isPreferred: ?bool,
    edit: ?WorkspaceEdit,
    command: ?Command,
};

pub const CodeActionRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    CodeActionOptions: CodeActionOptions,
};

pub const CodeLensParams = struct {
    textDocument: TextDocumentIdentifier,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const CodeLens = struct {
    range: Range,
    command: ?Command,
    data: ?JsonAny,
};

pub const CodeLensRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    resolveProvider: ?bool,
};

pub const DocumentLinkParams = struct {
    textDocument: TextDocumentIdentifier,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const DocumentLink = struct {
    range: Range,
    target: ?DocumentUri,
    toolTip: ?String,
    data: ?JsonAny,
};

pub const DocumentLinkRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    resolveProvider: ?bool,
};

pub const DocumentColorParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    textDocument: TextDocumentIdentifier,
};

pub const ColorInformation = struct {
    range: Range,
    color: Color,
};

pub const Color = struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

pub const ColorPresentationParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    textDocument: TextDocumentIdentifier,
    color: Color,
    range: Range,
};

pub const ColorPresentation = struct {
    label: String,
    textEdit: ?TextEdit,
    additionalTextEdits: ?[]TextEdit,
};

pub const DocumentFormattingParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    textDocument: TextDocumentIdentifier,
    options: FormattingOptions,
};

pub const FormattingOptions = struct {
    tabSize: isize,
    insertSpaces: bool,
    trimTrailingWhitespace: ?bool,
    insertFinalNewline: ?bool,
    trimFinalNewlines: ?bool,
};

pub const DocumentRangeFormattingParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    textDocument: TextDocumentIdentifier,
    range: Range,
    options: FormattingOptions,
};

pub const DocumentOnTypeFormattingParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
    ch: String,
    options: FormattingOptions,
};

pub const DocumentOnTypeFormattingRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    firstTriggerCharacter: String,
    moreTriggerCharacter: ?[]String,
};

pub const RenameParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    newName: String,
};

pub const RenameRegistrationOptions = struct {
    TextDocumentRegistrationOptions: TextDocumentRegistrationOptions,
    prepareProvider: ?bool,
};

pub const FoldingRangeParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    textDocument: TextDocumentIdentifier,
};

pub const FoldingRange = struct {
    startLine: isize,
    startCharacter: ?isize,
    endLine: isize,
    endCharacter: ?isize,
    kind: ?String,

    pub const kind_comment = "comment";
    pub const kind_imports = "imports";
    pub const kind_region = "region";
};

pub const SignatureHelpParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    context: ?SignatureHelpContext,
};

pub const WorkDoneProgressParams = struct {
    workDoneToken: ?ProgressToken,
};

pub const PartialResultParams = struct {
    partialResultToken: ?ProgressToken,
};

pub const ProgressToken = IntOrString;

pub const ProgressParams = struct {
    token: ProgressToken,
    value: JsonAny,
};

pub const WorkDoneProgress = struct {
    kind: String,
    title: String,
    cancellable: ?bool,
    message: ?String,
    percentage: ?isize,

    pub const kind_begin = "begin";
    pub const kind_report = "report";
    pub const kind_end = "end";
};

pub const SignatureHelpContext = struct {
    triggerKind: ?SignatureHelpTriggerKind,
    triggerCharacter: ?String,
    isRetrigger: bool,
    activeSignatureHelp: ?SignatureHelp,
};

pub const SignatureHelpTriggerKind = enum {
    Invoked = 1,
    TriggerCharacter = 2,
    ContentChange = 3,
};

pub const HoverParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
};

pub const DeclarationParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const DefinitionParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const TypeDefinitionParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const ImplementationParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const DocumentHighlightParams = struct {
    TextDocumentPositionParams: TextDocumentPositionParams,
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
};

pub const SelectionRange = struct {
    range: Range,
    parent: ?*SelectionRange,
};

pub const SelectionRangeParams = struct {
    WorkDoneProgressParams: WorkDoneProgressParams,
    PartialResultParams: PartialResultParams,
    textDocument: TextDocumentIdentifier,
    positions: []Position,
};

pub const WorkDoneProgressCreateParams = struct {
    token: ProgressToken,
};
