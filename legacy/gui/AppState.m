classdef AppState < handle
% AppState - wadah state untuk ImageEnhancementApp

    properties
        % ---- state aplikasi ----
        Original   = [];    % citra masukan (immutable)
        Result     = [];    % citra hasil chaining ([] = belum ada)
        Reference  = [];    % citra referensi untuk specification
        Steps      = {};    % riwayat langkah: cell array of string
        History    = {};    % tumpukan undo: cell of struct (.Result, .Steps)
        DatasetIdx = [];    % struktur dataset dari datasetIndex()
        OutFolder  = 'out'; % tujuan rekapan CSV dan figure batch

        % ---- container utama ----
        Figure     = [];
        LeftPanel  = [];
        RightPanel = [];
        Divider    = [];    % panel pemisah yang bisa di-drag
        DividerPos = 0.27; % posisi divider (normalized 0-1, default 27%)
        IsDragging = false; % status dragging
    end

    properties
        % ---- panel kontrol kiri ----
        FolderBox  = []; ImageBox = []; InfoLabel = [];
        TechBox    = []; InfoButton = [];
        ParamStack = [];

        % pilih citra & teknik
        Panels     = [];

        % panel intensity
        IntensityMode   = []; IntensityC   = [];
        IntensityGamma  = []; IntensityR1  = []; IntensityR2 = [];
        IntensitySMin = []; IntensitySMax = [];
        IntensityGrid = []; IntensityGrayHost = []; IntensityRGBHost = [];
        IntensityRGBIn = []; IntensityRGBOut = [];

        % panel image arithmetic
        ArithImage = []; ArithOperation = []; ArithOperand = []; ArithInfo = [];

        % tombol aksi
        UndoButton = [];

        % panel equalization
        EqualVariant = [];

        % panel specification
        RefFolderBox = []; RefImageBox = []; RefStatus = [];

        % panel filtering
        FilterType  = []; KernelSource = []; KernelSize = [];
        FilterParam1 = []; FilterParam2 = []; FilterParamLabel = []; NormalizeKernel = [];
        KernelHost  = []; KernelLayout = []; KernelTable = [];

        % panel tampilan kanan
        ImageInPanel  = []; ImageOutPanel  = [];
        AxImageIn     = []; AxImageOut     = [];
        HistInPanel   = []; HistOutPanel   = [];
        AxHistIn      = []; AxHistOut      = [];
        ChInPanel     = []; ChOutPanel     = [];
        AxChIn        = []; AxChOut        = []; HistMode = []; HistModeOut = []
        StatsPanel    = []; StatsTable     = []
        LogPanel      = []; LogText        = []; NoteText = []
    end
end
