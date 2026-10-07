function app = ImageEnhancementApp()
% ImageEnhancementApp - GUI analisis dan perbaikan kualitas citra

addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'src')));
addpath(fullfile(fileparts(mfilename('fullpath')), 'gui'));

app = initApp();
end

% ===========================================================================
% Pembangunan UI
% ===========================================================================

function app = initApp()

% ---- struktur utama -------------------------------------------------------
app = AppState();

app.DatasetIdx = datasetIndex('dataset');
app.OutFolder  = 'out';

% placeholder panel parameter per teknik; diisi oleh buildIntensityPanel dkk
app.Panels = struct('intensity', [], 'equalization', [], ...
    'specification', [], 'filtering', [], 'arithmetic', []);

app.Figure = uifigure( ...
    'Name',             'Analisis dan Perbaikan Kualitas Citra - IF4073', ...
    'Position',         [80 40 1240 760], ...
    'Theme',            'light', ...
    'Color',            [0.94 0.94 0.94], ...
    'AutoResizeChildren', false, ...
    'CloseRequestFcn',  @(src, ~) closeApp(src, app));

% ---- divider position (normalized 0-1) ----
app.DividerPos = 0.27;  % 27% from left
app.IsDragging = false;

% ---- pembagian: panel kontrol kiri + area tampilan kanan ----
% Gunakan panel dengan posisi manual agar bisa di-resize dengan drag divider
app.LeftPanel  = uipanel(app.Figure, ...
    'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', [0.96 0.96 0.96], ...
    'Units', 'normalized');

app.RightPanel = uipanel(app.Figure, ...
    'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', [0.94 0.94 0.94], ...
    'Units', 'normalized');

% ---- divider pemisah ----
app.Divider = uipanel(app.Figure, ...
    'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', [0.7 0.7 0.7], ...
    'Units', 'normalized');

% Atur posisi awal panel dan divider
updatePanelPositions(app);

% ---- bangun isi panel kiri dan kanan ----
buildLeftPanel(app);
buildRightPanel(app);

setEmptyState(app);

% ---- setup mouse callbacks untuk drag divider ----
setupDividerCallbacks(app);

% figure dibuat visible setelah semua komponen siap supaya tidak berkedip
app.Figure.Visible = 'on';
end

% ---------------------------------------------------------------------------
function app = buildLeftPanel(app)

p = uigridlayout(app.LeftPanel, [7 1]);
p.RowHeight = {22, 26, 108, 30, 26, '1x', 58};
p.RowSpacing = 4;
p.Padding = [8 8 8 8];
p.BackgroundColor = [0.96 0.96 0.96];

% --- 1. pilih citra ---------------------------------------------------------
uilabel(p, 'Text', '1. PILIH CITRA', 'FontWeight', 'bold', ...
    'FontColor', [0.15 0.25 0.45]);

% Tambah "Dari File..." di awal dropdown
allFolderItems = ['Dari File...', {app.DatasetIdx.folder}];
app.FolderBox = uidropdown(p, ...
    'Items',     allFolderItems, ...
    'Value',     app.DatasetIdx(1).folder, ...
    'Tooltip',   'Pilih folder dataset atau buka file citra eksternal', ...
    'BackgroundColor', 'w');
app.FolderBox.ValueChangedFcn = @(~, ~) onFolderChanged(app);

app.ImageBox = uilistbox(p, ...
    'Items',     app.DatasetIdx(1).files, ...
    'Value',     app.DatasetIdx(1).files{1}, ...
    'Tooltip',   'Citra di subfolder terpilih');
app.ImageBox.ValueChangedFcn = @(~, ~) onImageSelected(app);
app.ImageBox.Multiselect = 'off';


loadRow = uigridlayout(p, [1 3]);
loadRow.ColumnWidth = {'1x', 150, 30};
loadRow.Padding = [0 0 0 0];
loadRow.BackgroundColor = [0.96 0.96 0.96];
uibutton(loadRow, 'Text', 'Muat Citra', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.30 0.50 0.75], ...
    'FontColor', 'w', ...
    'ButtonPushedFcn', @(~, ~) loadSelectedImage(app));
app.InfoLabel = uilabel(loadRow, 'Text', '', ...
    'HorizontalAlignment', 'left', 'FontSize', 10, ...
    'FontColor', [0.2 0.2 0.2]);
app.InfoLabel.Layout.Column = 2;

% --- 2. pilih teknik -------------------------------------------------------
uilabel(p, 'Text', '2. TEKNIK ENHANCEMENT', 'FontWeight', 'bold', ...
    'FontColor', [0.15 0.25 0.45]);

techRow = uigridlayout(p, [1 2]);
techRow.ColumnWidth = {'1x', 30};
techRow.Padding = [0 0 0 0];
techRow.BackgroundColor = [0.96 0.96 0.96];
app.TechBox = uidropdown(techRow, ...
    'Items', {'Intensity Transformation', ...
              'Histogram Equalization', ...
              'Histogram Specification / Matching', ...
              'Image Filtering', ...
              'Image Arithmetic'}, ...
    'Value', 'Intensity Transformation', ...
    'BackgroundColor', 'w');
app.TechBox.ValueChangedFcn = @(~, ~) onTechniqueChanged(app);

% Tombol info untuk menampilkan popup tentang teknik
app.InfoButton = uibutton(techRow, 'Text', 'i', ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'BackgroundColor', [0.7 0.7 0.7], ...
    'Tooltip', 'Klik untuk info teknik', ...
    'ButtonPushedFcn', @(~, ~) showTechniqueInfo(app));

% --- panel parameter per teknik (hanya satu terlihat) -----------------------
app.ParamStack = uigridlayout(p, [5 1]);
app.ParamStack.RowHeight = {'1x','1x','1x','1x','1x'};
app.ParamStack.RowSpacing = 0;
app.ParamStack.Padding = [0 0 0 0];
app.ParamStack.BackgroundColor = [0.96 0.96 0.96];

app = buildIntensityPanel(app);
app = buildEqualizationPanel(app);
app = buildSpecificationPanel(app);
app = buildFilteringPanel(app);
app = buildArithmeticPanel(app);

% --- 3. aksi ---------------------------------------------------------------
actionRow = uigridlayout(p, [2 3]);
actionRow.RowHeight = {26, 26};
actionRow.ColumnWidth = {'1x','1x','1x'};
actionRow.RowSpacing = 6;
actionRow.ColumnSpacing = 6;
actionRow.Padding = [0 0 0 0];
actionRow.BackgroundColor = [0.96 0.96 0.96];

% baris 1: Terapkan | Undo | Reset
b1 = uibutton(actionRow, 'Text', 'Terapkan', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.20 0.55 0.35], ...
    'FontColor', 'w', ...
    'ButtonPushedFcn', @(~, ~) onApply(app));
app.UndoButton = uibutton(actionRow, 'Text', 'Undo', ...
    'BackgroundColor', [0.85 0.85 0.85], ...
    'Tooltip', 'Batalkan langkah terakhir (Terapkan atau Reset)', ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @(~, ~) onUndo(app));
b3 = uibutton(actionRow, 'Text', 'Reset', ...
    'BackgroundColor', [0.85 0.85 0.85], ...
    'ButtonPushedFcn', @(~, ~) onReset(app));

% baris 2: Simpan ke Temp | Kosongkan Temp | Simpan Rekapan
b4 = uibutton(actionRow, 'Text', 'Simpan ke Temp', ...
    'BackgroundColor', [0.75 0.85 0.95], ...
    'Tooltip', 'Simpan hasil saat ini ke dataset/tempProcess supaya bisa dipakai sebagai operan Image Arithmetic', ...
    'ButtonPushedFcn', @(~, ~) onSaveTemp(app));
b5 = uibutton(actionRow, 'Text', 'Kosongkan Temp', ...
    'BackgroundColor', [0.95 0.75 0.75], ...
    'Tooltip', 'Hapus semua citra di dataset/tempProcess', ...
    'ButtonPushedFcn', @(~, ~) onClearTemp(app));
b6 = uibutton(actionRow, 'Text', 'Simpan Rekapan', ...
    'BackgroundColor', [0.95 0.85 0.55], ...
    'ButtonPushedFcn', @(~, ~) onSaveRecord(app));

btns = {b1, app.UndoButton, b3, b4, b5, b6};
for k = 1:6
    btns{k}.Layout.Row    = ceil(k / 3);
    btns{k}.Layout.Column = mod(k - 1, 3) + 1;
end

% letakkan panel sesuai urutan row yang sudah ditentukan
app.FolderBox.Layout.Row = 2;
app.ImageBox.Layout.Row  = 3;
loadRow.Layout.Row      = 4;
techRow.Layout.Row      = 5;
app.ParamStack.Layout.Row = 6;
actionRow.Layout.Row    = 7;

onTechniqueChanged(app);
end

% ---------------------------------------------------------------------------
function app = buildIntensityPanel(app)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 1;
app.Panels.intensity = pnl;

g = uigridlayout(pnl, [5 2]);
g.RowHeight   = {28, 28, 28, 'fit', 0};
g.ColumnWidth = {110, '1x'};
g.RowSpacing  = 10;
g.ColumnSpacing = 6;
g.Padding = [10 10 10 10];
g.BackgroundColor = [0.99 0.99 0.99];
app.IntensityGrid = g;

uilabel(g, 'Text', 'Mode');
app.IntensityMode = uidropdown(g, ...
    'Items', {'negative', 'log', 'power', 'stretch', 'stretchRGB'}, ...
    'Value', 'stretch', ...
    'BackgroundColor', 'w', ...
    'Tooltip', 'stretchRGB: contrast stretching per kanal R,G,B (hanya untuk citra berwarna)');
app.IntensityMode.ValueChangedFcn = @(~, ~) updateIntensityFields(app);

uilabel(g, 'Text', 'c (log / power)');
app.IntensityC = uieditfield(g, 'numeric', ...
    'Value', 1.0, 'LowerLimitInclusive', 0, ...
    'Tooltip', 'Skala transformasi. Kosongkan untuk pakai nilai otomatis pada mode log.');

uilabel(g, 'Text', 'gamma (power)');
app.IntensityGamma = uieditfield(g, 'numeric', 'Value', 1.0, ...
    'Tooltip', 'gamma < 1 mencerahkan, gamma > 1 menggelapkan');

% --- stretch (grayscale): satu rentang input dan satu rentang target --------
grayHost = uigridlayout(g, [2 2]);
grayHost.Layout.Row = 4;
grayHost.Layout.Column = [1 2];
grayHost.ColumnWidth = {110, '1x'};
grayHost.RowHeight = {28, 28};
grayHost.RowSpacing = 10;
grayHost.ColumnSpacing = 6;
grayHost.Padding = [0 0 0 0];
grayHost.BackgroundColor = [0.99 0.99 0.99];
app.IntensityGrayHost = grayHost;

uilabel(grayHost, 'Text', 'Input min, maks');
boundsRow = uigridlayout(grayHost, [1 3]);
boundsRow.ColumnWidth = {'1x', '1x', 62};
boundsRow.ColumnSpacing = 6;
boundsRow.Padding = [0 0 0 0];
boundsRow.BackgroundColor = [0.99 0.99 0.99];
app.IntensityR1 = uieditfield(boundsRow, 'numeric', 'Value', 0, ...
    'Tooltip', 'Batas bawah rentang input (default: min grayscale citra)');
app.IntensityR2 = uieditfield(boundsRow, 'numeric', 'Value', 255, ...
    'Tooltip', 'Batas atas rentang input (default: maks grayscale citra)');
uibutton(boundsRow, 'Text', 'Ambil', 'FontSize', 9, ...
    'Tooltip', 'Isi dengan min/maks grayscale citra yang sedang dimuat', ...
    'ButtonPushedFcn', @(~, ~) onTakeBounds(app));

uilabel(grayHost, 'Text', 'Target min, maks');
targetRow = uigridlayout(grayHost, [1 2]);
targetRow.ColumnWidth = {'1x', '1x'};
targetRow.ColumnSpacing = 6;
targetRow.Padding = [0 0 0 0];
targetRow.BackgroundColor = [0.99 0.99 0.99];
app.IntensitySMin = uieditfield(targetRow, 'numeric', 'Value', 0, ...
    'Limits', [0 255], 'Tooltip', 'Nilai target untuk batas bawah input (default 0)');
app.IntensitySMax = uieditfield(targetRow, 'numeric', 'Value', 255, ...
    'Limits', [0 255], 'Tooltip', 'Nilai target untuk batas atas input (default 255)');

% --- stretchRGB: rentang input dan target per kanal -----------------------
rgbHost = uigridlayout(g, [7 2]);
rgbHost.Layout.Row = 5;
rgbHost.Layout.Column = [1 2];
rgbHost.ColumnWidth = {110, '1x'};
rgbHost.RowHeight = repmat({28}, 1, 7);
rgbHost.RowSpacing = 10;
rgbHost.ColumnSpacing = 6;
rgbHost.Padding = [0 0 0 0];
rgbHost.BackgroundColor = [0.99 0.99 0.99];
app.IntensityRGBHost = rgbHost;

nama  = {'R', 'G', 'B'};
warna = {[0.75 0 0], [0 0.55 0], [0 0 0.75]};
app.IntensityRGBIn  = gobjects(3, 2);
app.IntensityRGBOut = gobjects(3, 2);

for k = 1:3
    lbl = uilabel(rgbHost, 'Text', sprintf('Input %s min, maks', nama{k}));
    lbl.FontColor = warna{k};
    row = uigridlayout(rgbHost, [1 2]);
    row.ColumnSpacing = 6;
    row.Padding = [0 0 0 0];
    row.BackgroundColor = [0.99 0.99 0.99];
    app.IntensityRGBIn(k, 1) = uieditfield(row, 'numeric', 'Value', 0, ...
        'Limits', [0 255], 'Tooltip', sprintf('Min kanal %s pada citra', nama{k}));
    app.IntensityRGBIn(k, 2) = uieditfield(row, 'numeric', 'Value', 255, ...
        'Limits', [0 255], 'Tooltip', sprintf('Maks kanal %s pada citra', nama{k}));
end

for k = 1:3
    lbl = uilabel(rgbHost, 'Text', sprintf('Target %s min, maks', nama{k}));
    lbl.FontColor = warna{k};
    row = uigridlayout(rgbHost, [1 2]);
    row.ColumnSpacing = 6;
    row.Padding = [0 0 0 0];
    row.BackgroundColor = [0.99 0.99 0.99];
    app.IntensityRGBOut(k, 1) = uieditfield(row, 'numeric', 'Value', 0, ...
        'Limits', [0 255], 'Tooltip', sprintf('Target min kanal %s (default 0)', nama{k}));
    app.IntensityRGBOut(k, 2) = uieditfield(row, 'numeric', 'Value', 255, ...
        'Limits', [0 255], 'Tooltip', sprintf('Target maks kanal %s (default 255)', nama{k}));
end

uilabel(rgbHost, 'Text', '');
btn = uibutton(rgbHost, 'Text', 'Ambil min/maks per kanal', ...
    'Tooltip', 'Isi rentang input dengan min/maks kanal R,G,B citra yang sedang dimuat', ...
    'ButtonPushedFcn', @(~, ~) onTakeBounds(app));
btn.Layout.Column = 2;

updateStretchRGBAvailability(app);
end

% ---------------------------------------------------------------------------
function app = buildEqualizationPanel(app)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 2;
app.Panels.equalization = pnl;

g = uigridlayout(pnl, [3 1]);
g.RowHeight = {22, 22, '1x'};
g.RowSpacing = 4;
g.Padding = [6 6 6 6];
g.BackgroundColor = [0.99 0.99 0.99];

uilabel(g, 'Text', 'Varian perataan histogram');
app.EqualVariant = uidropdown(g, ...
    'Items', {'lightness', 'rgb', 'grayscale'}, ...
    'Value', 'lightness', ...
    'BackgroundColor', 'w');

msg = uilabel(g, 'Text', {'', ...
    'lightness : perataan pada kanal L (Lab), warna tetap terjaga', ...
    'rgb        : perataan terpisah tiap kanal R,G,B, warna bisa bergeser', ...
    'grayscale  : hanya untuk citra abu-abu; pada citra berwarna otomatis'}, ...
    'FontSize', 9, 'FontColor', [0.3 0.3 0.3]);
msg.WordWrap = 'on';
end

% ---------------------------------------------------------------------------
function app = buildSpecificationPanel(app)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 3;
app.Panels.specification = pnl;

g = uigridlayout(pnl, [4 2]);
g.RowHeight   = {22, '1x', 26, 22};
g.ColumnWidth = {90, '1x'};
g.RowSpacing  = 3;
g.ColumnSpacing = 4;
g.Padding = [6 6 6 6];
g.BackgroundColor = [0.99 0.99 0.99];

uilabel(g, 'Text', 'Subfolder');
allRefFolders = ['Dari File...', {app.DatasetIdx.folder}];
app.RefFolderBox = uidropdown(g, ...
    'Items', allRefFolders, ...
    'Value', app.DatasetIdx(1).folder, ...
    'BackgroundColor', 'w');
app.RefFolderBox.ValueChangedFcn = @(~, ~) onRefFolderChanged(app);

uilabel(g, 'Text', 'Referensi');
app.RefImageBox = uilistbox(g, ...
    'Items', app.DatasetIdx(1).files, ...
    'Value', app.DatasetIdx(1).files{1});
app.RefImageBox.Multiselect = 'off';

% Baris 3: tombol-tombol
uibutton(g, 'Text', 'Pakai Citra Terpilih', ...
    'ButtonPushedFcn', @(~, ~) onUseReference(app));
uibutton(g, 'Text', 'Dari File...', ...
    'ButtonPushedFcn', @(~, ~) onOpenReferenceFile(app));

% Baris 4: status referensi
app.RefStatus = uilabel(g, 'Text', 'Belum ada citra referensi dipilih', ...
    'FontSize', 9, 'FontColor', [0.5 0.1 0.1]);
app.RefStatus.Layout.Row = 4;
app.RefStatus.Layout.Column = [1 2];
end

% ---------------------------------------------------------------------------
function app = buildFilteringPanel(app)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 4;
app.Panels.filtering = pnl;

g = uigridlayout(pnl, [6 2]);
g.RowHeight   = {22, 22, 22, 22, 22, '1x'};
g.ColumnWidth = {90, '1x'};
g.RowSpacing  = 6;
g.ColumnSpacing = 4;
g.Padding = [6 6 6 6];
g.BackgroundColor = [0.99 0.99 0.99];

uilabel(g, 'Text', 'Jenis');
app.FilterType = uidropdown(g, ...
    'Items', {'linear', 'median'}, 'Value', 'linear', ...
    'BackgroundColor', 'w');
app.FilterType.ValueChangedFcn = @(~, ~) updateFilteringFields(app);

uilabel(g, 'Text', 'Kernel');
app.KernelSource = uidropdown(g, ...
    'Items', {'gaussian', 'mean', 'sharpen', 'custom'}, ...
    'Value', 'gaussian', ...
    'BackgroundColor', 'w', ...
    'Tooltip', 'Memilih kernel bawaan mengisi grid di bawah. Mengubah isi grid otomatis menjadi custom.');
app.KernelSource.ValueChangedFcn = @(~, ~) onKernelSourceChanged(app);

uilabel(g, 'Text', 'Ukuran');
app.KernelSize = uidropdown(g, ...
    'Items', {'3', '5', '7', '9'}, 'Value', '3', ...
    'BackgroundColor', 'w');
app.KernelSize.ValueChangedFcn = @(~, ~) onKernelSizeChanged(app);

% satu sel untuk parameter: field yang tampil bergantung pada jenis/kernel
app.FilterParamLabel = uilabel(g, 'Text', 'Sigma');
paramCell = uigridlayout(g, [1 1]);
paramCell.Padding = [0 0 0 0];
paramCell.BackgroundColor = [0.99 0.99 0.99];
app.FilterParam1 = uieditfield(paramCell, 'numeric', 'Value', 2.0, ...
    'Tooltip', 'Gaussian: sigma | Sharpen: bobot');
app.FilterParam1.Layout.Row = 1;
app.FilterParam1.Layout.Column = 1;
app.FilterParam1.ValueChangedFcn = @(~, ~) fillKernelTable(app);
app.FilterParam2 = uieditfield(paramCell, 'numeric', 'Value', 15, ...
    'Tooltip', 'Median: ukuran window');
app.FilterParam2.Layout.Row = 1;
app.FilterParam2.Layout.Column = 1;

% normalisasi dilakukan di backend (applyEnhancement), grid hanya menampilkan nilai mentah
app.NormalizeKernel = uicheckbox(g, ...
    'Text', 'Normalisasi kernel (bagi dengan jumlah elemen)', ...
    'Value', true, ...
    'Tooltip', ['Aktif: kernel dibagi jumlah elemennya sebelum dikonvolusi. ' ...
                'Nonaktif: nilai grid dipakai apa adanya, hasil hanya di-clip ke 0-255.']);
app.NormalizeKernel.Layout.Row = 5;
app.NormalizeKernel.Layout.Column = [1 2];

% grid kernel: uitable supaya mengetik pada sel terpilih langsung menimpa nilainya
app.KernelHost = uipanel(g, 'Title', 'Kernel', 'BorderType', 'line', ...
    'BackgroundColor', 'w');
app.KernelHost.Layout.Row = 6;
app.KernelHost.Layout.Column = [1 2];
app.KernelLayout = uigridlayout(app.KernelHost, [1 1]);
app.KernelLayout.Padding = [2 2 2 2];
app.KernelLayout.BackgroundColor = 'w';
app.KernelTable = uitable(app.KernelLayout, ...
    'Data', zeros(3), ...
    'ColumnName', {}, 'RowName', {}, ...
    'ColumnEditable', true, ...
    'ColumnWidth', 'auto', ...
    'FontSize', 12, ...
    'RowStriping', 'off', ...
    'CellEditCallback', @(~, evt) onKernelCellEdited(app, evt));
addStyle(app.KernelTable, uistyle('HorizontalAlignment', 'center'));

fillKernelTable(app);
updateFilteringFields(app);
end

% ---------------------------------------------------------------------------
function app = buildArithmeticPanel(app)

pnl = uipanel(app.ParamStack, 'Title', '', 'BorderType', 'line', ...
    'BackgroundColor', [0.99 0.99 0.99]);
pnl.Layout.Row = 5;
app.Panels.arithmetic = pnl;

g = uigridlayout(pnl, [5 2]);
g.RowHeight   = {28, 28, 28, 44, '1x'};
g.ColumnWidth = {90, '1x'};
g.RowSpacing  = 10;
g.ColumnSpacing = 6;
g.Padding = [10 10 10 10];
g.BackgroundColor = [0.99 0.99 0.99];

uilabel(g, 'Text', 'Citra 1');
app.ArithImage = uidropdown(g, ...
    'Items', {currentResultLabel()}, ...
    'BackgroundColor', 'w', ...
    'Tooltip', ['Citra pertama: hasil saat ini, citra masukan asli, atau hasil yang disimpan ' ...
                'lewat "Simpan ke Temp"']);
app.ArithImage.ValueChangedFcn = @(~, ~) updateOperandInfo(app);

uilabel(g, 'Text', 'Operasi');
app.ArithOperation = uidropdown(g, ...
    'Items', {'Tambah (Citra 1 + Citra 2)', 'Kurang (Citra 1 - Citra 2)'}, ...
    'ItemsData', {'add', 'subtract'}, ...
    'Value', 'subtract', ...
    'BackgroundColor', 'w', ...
    'Tooltip', 'Hasil di luar 0-255 di-clip. Untuk Citra 2 - Citra 1, tukar pilihan kedua citra.');

uilabel(g, 'Text', 'Citra 2');
app.ArithOperand = uidropdown(g, ...
    'Items', {originalOperandLabel()}, ...
    'BackgroundColor', 'w', ...
    'Tooltip', 'Citra kedua: hasil saat ini, citra masukan asli, atau file di dataset/tempProcess');
app.ArithOperand.ValueChangedFcn = @(~, ~) updateOperandInfo(app);

app.ArithInfo = uilabel(g, 'Text', '', 'WordWrap', 'on', 'FontSize', 10, ...
    'VerticalAlignment', 'top');
app.ArithInfo.Layout.Row = 4;
app.ArithInfo.Layout.Column = [1 2];

hint = uilabel(g, 'Text', ['Kedua citra harus berukuran dan berjumlah kanal sama. ' ...
    'Simpan hasil dengan "Simpan ke Temp" agar muncul di daftar pilihan.'], ...
    'WordWrap', 'on', 'FontSize', 9, 'FontColor', [0.3 0.3 0.3], ...
    'VerticalAlignment', 'top');
hint.Layout.Row = 5;
hint.Layout.Column = [1 2];

refreshOperandList(app);
end

% ---------------------------------------------------------------------------
function app = buildRightPanel(app)

g = uigridlayout(app.RightPanel, [4 2]);
g.ColumnWidth = {'1x', '1x'};
g.RowHeight   = {'1x', '0.85x', '1x', 200};
g.RowSpacing  = 6;
g.ColumnSpacing = 6;
g.Padding = [0 0 0 0];
g.BackgroundColor = [0.94 0.94 0.94];

% baris 1: citra
app.ImageInPanel  = makeDisplayPanel(g, 'CITRA MASUKAN', 1, 1);
app.ImageOutPanel = makeDisplayPanel(g, 'CITRA HASIL',    1, 2);

% Gunakan axes biasa dengan posisi eksplisit agar mengisi panel
% Posisi [left bottom width height] - disesuaikan agar tidak overlap dengan panel title
app.AxImageIn = axes('Parent', app.ImageInPanel);
app.AxImageIn.Position = [0.02, 0.10, 0.96, 0.86];
app.AxImageIn.Visible = 'off';

app.AxImageOut = axes('Parent', app.ImageOutPanel);
app.AxImageOut.Position = [0.02, 0.10, 0.96, 0.86];
app.AxImageOut.Visible = 'off';

% baris 2: histogram grayscale
app.HistInPanel  = makeDisplayPanel(g, 'HISTOGRAM ABU-ABU - MASUKAN', 2, 1);
app.HistOutPanel = makeDisplayPanel(g, 'HISTOGRAM ABU-ABU - HASIL',    2, 2);
app.AxHistIn  = makeHistogramAxes(app.HistInPanel);
app.AxHistOut = makeHistogramAxes(app.HistOutPanel);

% baris 3: histogram per kanal
app.ChInPanel  = makeDisplayPanel(g, 'HISTOGRAM KANAL R,G,B - MASUKAN', 3, 1);
app.ChOutPanel = makeDisplayPanel(g, 'HISTOGRAM KANAL R,G,B - HASIL',    3, 2);

% dropdown tampilan histogram RGB di tiap panel (keduanya disinkronkan)
[app.HistMode, chInGrid] = makeHistModeGrid(app, app.ChInPanel);
app.AxChIn = makeChannelAxes(chInGrid);
[app.HistModeOut, chOutGrid] = makeHistModeGrid(app, app.ChOutPanel);
app.AxChOut = makeChannelAxes(chOutGrid);

% baris 4: tabel fitur + catatan
app.StatsPanel = makeDisplayPanel(g, 'FITUR CITRA', 4, 1);
app.StatsTable = uitable(app.StatsPanel, ...
    'ColumnName', {'Fitur', 'Masukan', 'Hasil'}, ...
    'ColumnWidth', {'auto', 'auto', 'auto'}, ...
    'RowName', {}, ...
    'FontSize', 10, ...
    'BackgroundColor', 'w', ...
    'Units', 'normalized', ...
    'Position', [0, 0, 1, 1]);

app.LogPanel = makeDisplayPanel(g, 'METODE, PARAMETER & CATATAN', 4, 2);
inner = uigridlayout(app.LogPanel, [2 1]);
inner.RowHeight = {'1x', '2x'};
inner.RowSpacing = 4;
inner.Padding = [0 2 0 2];
inner.BackgroundColor = app.LogPanel.BackgroundColor;

app.LogText = uitextarea(inner, ...
    'Value', {'Belum ada langkah enhancement.'}, ...
    'Editable', 'off', 'FontSize', 10, ...
    'BackgroundColor', [1 1 1]);

app.NoteText = uitextarea(inner, ...
    'Value', {''}, 'Editable', 'on', 'FontSize', 10, ...
    'Placeholder', 'Catatan analisis: masalah kualitas visual yang terlihat dan alasan pemilihan metode...', ...
    'BackgroundColor', [1 1 1], 'Tooltip', 'Identifikasi singkat masalah citra + alasan metode (untuk laporan)');
end

% ---------------------------------------------------------------------------
function pnl = makeDisplayPanel(parent, title, row, col)
pnl = uipanel(parent, 'Title', title, 'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BorderType', 'line', 'BackgroundColor', 'w');
pnl.Layout.Row = row;
pnl.Layout.Column = col;
end

% ---------------------------------------------------------------------------
function ax = makeHistogramAxes(parent)
lay = uigridlayout(parent, [1 1]);
lay.Padding = [2 2 2 2];
lay.BackgroundColor = 'w';
ax = uiaxes(lay);
ax.Layout.Row = 1;
ax.Layout.Column = 1;
end

function [dd, grid] = makeHistModeGrid(app, panel)
grid = uigridlayout(panel, [2 1]);
grid.RowHeight = {22, '1x'};
grid.RowSpacing = 2;
grid.Padding = [0 0 0 0];
grid.BackgroundColor = 'w';
dd = uidropdown(grid, ...
    'Items', {'R,G,B terpisah', 'R,G,B gabungan'}, ...
    'ItemsData', {'separate', 'combined'}, ...
    'Value', 'separate', ...
    'BackgroundColor', 'w', ...
    'Tooltip', 'Tampilan histogram RGB: tiga histogram terpisah atau satu histogram gabungan');
dd.Layout.Row = 1;
dd.ValueChangedFcn = @(src, ~) onHistModeChanged(app, src.Value);
end

function ax = makeChannelAxes(parent)
% tiga axes kecil untuk histogram kanal R, G, B di dalam satu panel
lay = uigridlayout(parent, [1 3]);
if isa(parent, 'matlab.ui.container.GridLayout')
    lay.Layout.Row = 2;
end
lay.ColumnWidth = {'1x', '1x', '1x'};
lay.ColumnSpacing = 2;
lay.Padding = [2 2 2 2];
lay.BackgroundColor = 'w';
ax = gobjects(1, 3);
ax(1) = uiaxes(lay); ax(1).Layout.Column = 1;
ax(2) = uiaxes(lay); ax(2).Layout.Column = 2;
ax(3) = uiaxes(lay); ax(3).Layout.Column = 3;
end

% ===========================================================================
% Callback
% ===========================================================================

function onFolderChanged(app)
folder = app.FolderBox.Value;

% Cek apakah "Dari File..." dipilih
if strcmp(folder, 'Dari File...')
    onOpenImageFile(app);
    return;
end

k = find(strcmp({app.DatasetIdx.folder}, folder), 1);
if isempty(k), return; end
app.ImageBox.Items = app.DatasetIdx(k).files;
app.ImageBox.Value = app.DatasetIdx(k).files{1};

% panel referensi ikut folder terpilih supaya gampang ganti referensi
app.RefFolderBox.Value = folder;
onRefFolderChanged(app);
end

function onOpenImageFile(app)
% Buka dialog untuk memilih citra dari file eksternal
[fileName, pathName] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', ...
    'File citra (*.png, *.jpg, *.bmp, *.tif)'; '*.*', 'Semua file'}, ...
    'Pilih citra');

if isequal(fileName, 0)
    % Jika dibatalkan, kembali ke folder default
    app.FolderBox.Value = app.DatasetIdx(1).folder;
    return;
end

try
    img = imread(fullfile(pathName, fileName));

    app.Original = img;
    app.Result   = [];
    app.Steps    = {};
    resetHistory(app);
    fillSourceRange(app);

    % Update info label
    app.InfoLabel.Text = sprintf('Eksternal: %s', fileName);

    app.LogText.Value = {'Citra dari file eksternal dimuat.'};
    app.NoteText.Value = {''};

    refreshAll(app);
catch ex
    uialert(app.Figure, sprintf('Gagal membaca citra:\n%s', ex.message), ...
        'Citra tidak bisa dimuat');
end
end

function onRefFolderChanged(app)
folder = app.RefFolderBox.Value;

% Cek apakah "Dari File..." dipilih
if strcmp(folder, 'Dari File...')
    onOpenReferenceFile(app);
    return;
end

k = find(strcmp({app.DatasetIdx.folder}, folder), 1);
if isempty(k), return; end
app.RefImageBox.Items = app.DatasetIdx(k).files;
app.RefImageBox.Value = app.RefImageBox.Items{1};
end

function onImageSelected(~)
% seleksi listbox tidak langsung memuat; pengguna tekan "Muat Citra"
end

function loadSelectedImage(app)
folder = app.FolderBox.Value;
file   = app.ImageBox.Value;
k = find(strcmp({app.DatasetIdx.folder}, folder), 1);
if isempty(k)
    uialert(app.Figure, 'Subfolder dataset tidak dikenali.', 'Citra tidak bisa dimuat');
    return;
end

try
    img = imread(fullfile(app.DatasetIdx(k).path, file));
catch ex
    uialert(app.Figure, sprintf('Gagal membaca citra:\\n%s', ex.message), ...
        'Citra tidak bisa dimuat');
    return;
end

app.Original = img;
app.Result   = [];
app.Steps    = {};
resetHistory(app);
fillSourceRange(app);

% baris kanal histogram hanya relevan untuk citra berwarna
isColor = (size(img, 3) == 3);
app.ChInPanel.Visible  = isColor;
app.ChOutPanel.Visible = isColor;
setRowVisible(app.ChInPanel.Parent, 3, isColor);
setRowVisible(app.ChOutPanel.Parent, 3, isColor);

if isColor
    app.InfoLabel.Text = sprintf('RGB %dx%d', size(img, 1), size(img, 2));
else
    app.InfoLabel.Text = sprintf('Abu-abu %dx%d', size(img, 1), size(img, 2));
end

app.LogText.Value = {'Belum ada langkah enhancement. Citra masukan sudah dimuat.'};
app.NoteText.Value = {''};

refreshAll(app);
end

function onTechniqueChanged(app)
tech = app.TechBox.Value;

    app.Panels.intensity.Visible       = strcmp(tech, 'Intensity Transformation');
    app.Panels.equalization.Visible    = strcmp(tech, 'Histogram Equalization');
    app.Panels.specification.Visible   = strcmp(tech, 'Histogram Specification / Matching');
    app.Panels.filtering.Visible       = strcmp(tech, 'Image Filtering');
    app.Panels.arithmetic.Visible      = strcmp(tech, 'Image Arithmetic');

    % uigridlayout tetap mengalokasikan tinggi untuk baris yang komponennya
    % disembunyikan, jadi baris panel non-aktif dilipat supaya panel yang aktif
    % mendapat seluruh ruang. Tanpa ini panel Image Filtering hanya terpaut
    % ~1/4 tinggi dan grid kernel kustom kekurangan tempat.
    setPanelRowVisible(app, 'intensity',     app.Panels.intensity.Visible);
    setPanelRowVisible(app, 'equalization',  app.Panels.equalization.Visible);
    setPanelRowVisible(app, 'specification', app.Panels.specification.Visible);
    setPanelRowVisible(app, 'filtering',     app.Panels.filtering.Visible);
    setPanelRowVisible(app, 'arithmetic',    app.Panels.arithmetic.Visible);

% tampilkan field yang relevan untuk teknik terpilih
updateIntensityFields(app);
updateFilteringFields(app);
if strcmp(tech, 'Image Arithmetic')
    refreshOperandList(app);    % daftar temp bisa berubah sejak terakhir dibuka
end
end

function showTechniqueInfo(app)
% Tampilkan popup dengan info tentang teknik yang dipilih
tech = app.TechBox.Value;
info = techniqueTooltip(tech);

% Ekstrak judul teknik
switch tech
    case 'Intensity Transformation'
        title = 'Intensity Transformation';
    case 'Histogram Equalization'
        title = 'Histogram Equalization';
    case 'Histogram Specification / Matching'
        title = 'Histogram Specification / Matching';
    case 'Image Filtering'
        title = 'Image Filtering';
    case 'Image Arithmetic'
        title = 'Image Arithmetic';
end

% Tampilkan dialog info
uiconfirm(app.Figure, info, title, ...
    'Options', {'OK'}, ...
    'Icon', 'info');
end

function updateIntensityFields(app)
if isempty(app.IntensityMode)
    return;
end
mode = app.IntensityMode.Value;
isLog     = strcmp(mode, 'log');
isPower   = strcmp(mode, 'power');
isStretch = strcmp(mode, 'stretch');
isRGB     = strcmp(mode, 'stretchRGB');

app.IntensityC.Enable        = logical(isLog || isPower);
app.IntensityGamma.Enable    = isPower;
app.IntensityR1.Enable       = isStretch;
app.IntensityR2.Enable       = isStretch;
app.IntensitySMin.Enable     = isStretch;
app.IntensitySMax.Enable     = isStretch;

% blok stretch grayscale dan stretchRGB saling menggantikan
app.IntensityGrayHost.Visible = ~isRGB;
app.IntensityRGBHost.Visible  = isRGB;
if isRGB
    app.IntensityGrid.RowHeight = {28, 28, 28, 0, 'fit'};
else
    app.IntensityGrid.RowHeight = {28, 28, 28, 'fit', 0};
end

if isPower && app.IntensityGamma.Value == 1.0
    % beri nilai awal yang bermakna supaya tidak identik
    app.IntensityGamma.Value = 2.5;
end
end

function updateStretchRGBAvailability(app)
% pilihan stretchRGB hanya ada kalau citra yang dimuat berwarna (3 kanal)
isColor = ~isempty(app.Original) && size(app.Original, 3) == 3;
if isColor
    app.IntensityMode.Items = {'negative', 'log', 'power', 'stretch', 'stretchRGB'};
else
    if strcmp(app.IntensityMode.Value, 'stretchRGB')
        app.IntensityMode.Value = 'stretch';
    end
    app.IntensityMode.Items = {'negative', 'log', 'power', 'stretch'};
end
updateIntensityFields(app);
end

function updateFilteringFields(app)
if isempty(app.FilterType)
    return;
end
jenis = app.FilterType.Value;
isLinear = strcmp(jenis, 'linear');
isMedian = strcmp(jenis, 'median');
src = app.KernelSource.Value;
hasParam1 = isLinear && any(strcmp(src, {'gaussian', 'sharpen'}));

app.KernelSource.Visible  = isLinear;
app.KernelSource.Enable   = isLinear;
app.KernelSize.Visible    = isLinear;
app.KernelSize.Enable     = isLinear;
app.FilterParam1.Visible  = hasParam1;
app.FilterParam1.Enable   = hasParam1;
app.FilterParam2.Visible  = isMedian;
app.FilterParam2.Enable   = isMedian;
app.FilterParamLabel.Visible = hasParam1 || isMedian;
app.KernelHost.Visible    = isLinear;
app.NormalizeKernel.Visible = isLinear;

if isMedian
    app.FilterParamLabel.Text = 'Ukuran window';
elseif strcmp(src, 'sharpen')
    app.FilterParamLabel.Text = 'Bobot';
    app.FilterParam1.Tooltip = 'Bobot sharpen';
else
    app.FilterParamLabel.Text = 'Sigma';
    app.FilterParam1.Tooltip = 'Sigma distribusi Gaussian';
end
end

function onKernelSourceChanged(app)
updateFilteringFields(app);
fillKernelTable(app);
end

function onKernelSizeChanged(app)
n = str2double(app.KernelSize.Value);
if strcmp(app.KernelSource.Value, 'custom')
    % pertahankan isi lama di tengah, sisanya nol
    old = app.KernelTable.Data;
    m = min(n, size(old, 1));
    o = (size(old, 1) - m) / 2;
    q = (n - m) / 2;
    new = zeros(n);
    new(q + 1:q + m, q + 1:q + m) = old(o + 1:o + m, o + 1:o + m);
    app.KernelTable.Data = new;
else
    fillKernelTable(app);
end
end

function fillKernelTable(app)
% isi grid dengan kernel bawaan sesuai pilihan; custom tidak diubah
src = app.KernelSource.Value;
if strcmp(src, 'custom')
    return;
end
n = str2double(app.KernelSize.Value);
k = presetKernel(src, n, app.FilterParam1.Value);
if isempty(k)
    return;     % parameter belum valid (mis. sigma <= 0), biarkan grid apa adanya
end
app.KernelTable.Data = k;
end

function onKernelCellEdited(app, evt)
% isian tidak valid dikembalikan; isian valid mengubah kernel jadi custom
if ~isnumeric(evt.NewData) || isnan(evt.NewData)
    app.KernelTable.Data(evt.Indices(1), evt.Indices(2)) = evt.PreviousData;
    return;
end
if ~strcmp(app.KernelSource.Value, 'custom')
    app.KernelSource.Value = 'custom';
    updateFilteringFields(app);
end
end

function onTakeBounds(app)
if isempty(app.Original)
    uialert(app.Figure, 'Muat citra dulu sebelum mengambil min/maks.', ...
        'Citra belum dimuat');
    return;
end
fillSourceRange(app);
end

function fillSourceRange(app)
% isi rentang input dengan min/maks citra: grayscale (RGB -> grayscale) dan per kanal
img = app.Original;
if isempty(img), return; end

isColor = (size(img, 3) == 3);
gray = img;
if isColor
    gray = rgb2gray(img);
    for k = 1:3
        ch = img(:, :, k);
        app.IntensityRGBIn(k, 1).Value = double(min(ch(:)));
        app.IntensityRGBIn(k, 2).Value = double(max(ch(:)));
    end
end
app.IntensityR1.Value = double(min(gray(:)));
app.IntensityR2.Value = double(max(gray(:)));
updateStretchRGBAvailability(app);
updateOperandInfo(app);
end

function onUseReference(app)
folder = app.RefFolderBox.Value;
file   = app.RefImageBox.Value;
k = find(strcmp({app.DatasetIdx.folder}, folder), 1);
if isempty(k), return; end

try
    app.Reference = imread(fullfile(app.DatasetIdx(k).path, file));
    app.RefStatus.Text = sprintf('Referensi: %s / %s', folder, file);
    app.RefStatus.FontColor = [0.2 0.5 0.2];
catch ex
    uialert(app.Figure, sprintf('Gagal membaca citra referensi:\\n%s', ex.message), ...
        'Referensi tidak bisa dimuat');
end
end

function onOpenReferenceFile(app)
[fileName, pathName] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', ...
    'File citra (*.png, *.jpg, *.bmp, *.tif)'; '*.*', 'Semua file'}, ...
    'Pilih citra referensi');

if isequal(fileName, 0), return; end   % pengguna membatalkan

try
    app.Reference = imread(fullfile(pathName, fileName));
    app.RefStatus.Text = sprintf('Referensi: %s (file eksternal)', fileName);
    app.RefStatus.FontColor = [0.2 0.5 0.2];
catch ex
    uialert(app.Figure, sprintf('Gagal membaca citra referensi:\\n%s', ex.message), ...
        'Referensi tidak bisa dimuat');
end
end

function onApply(app)
if isempty(app.Original)
    uialert(app.Figure, 'Muat citra dulu sebelum menerapkan enhancement.', ...
        'Citra belum dimuat');
    return;
end

try
    [tech, params] = collectInputs(app);
catch ex
    uialert(app.Figure, ex.message, 'Parameter belum lengkap');
    return;
end

% chaining: langkah berikutnya memakai hasil sebelumnya
base = app.Result;
if isempty(base)
    base = app.Original;
end
if strcmp(tech, 'arithmetic')
    base = params.image;    % Citra 1 dipilih sendiri di panel, tidak otomatis hasil terakhir
end

try
    [result, methodName, paramText] = applyEnhancement(base, tech, params);
catch ex
    uialert(app.Figure, sprintf('%s\\n\\n%s', ex.message, ...
        'Perbaiki parameter lalu tekan Terapkan lagi.'), 'Enhancement gagal');
    return;
end

pushHistory(app);      % simpan keadaan sebelum langkah ini supaya bisa di-undo
app.Result = result;
app.Steps{end + 1} = sprintf('%s | %s', methodName, paramText);

showLog(app);
refreshAll(app);
end

function onReset(app)
if ~isempty(app.Result)
    pushHistory(app);
end
app.Result = [];
app.Steps  = {};
showLog(app);
refreshAll(app);
end

% ---------------------------------------------------------------------------
% Undo dan hasil antara (tempProcess)
% ---------------------------------------------------------------------------

function n = maxHistory()
n = 20;
end

function pushHistory(app)
st.Result = app.Result;
st.Steps  = app.Steps;
app.History{end + 1} = st;
if numel(app.History) > maxHistory()
    app.History(1) = [];        % buang history terlama
end
updateUndoButton(app);
end

function resetHistory(app)
app.History = {};
updateUndoButton(app);
end

function updateUndoButton(app)
if isempty(app.UndoButton) || ~isvalid(app.UndoButton)
    return;
end
if isempty(app.History)
    app.UndoButton.Enable = 'off';
else
    app.UndoButton.Enable = 'on';
end
end

function onUndo(app)
if isempty(app.History)
    return;
end
st = app.History{end};
app.History(end) = [];
app.Result = st.Result;
app.Steps  = st.Steps;      %steps juga diundo
showLog(app);
refreshAll(app);
updateUndoButton(app);
end

function showLog(app)
if isempty(app.Steps)
    app.LogText.Value = {'Belum ada langkah enhancement. Citra dikembalikan ke masukan.'};
else
    app.LogText.Value = [{'Langkah enhancement yang sudah diterapkan:'}, app.Steps];
end
end

function onSaveTemp(app)
if isempty(app.Original)
    uialert(app.Figure, 'Muat citra dulu sebelum menyimpan hasil.', 'Citra belum dimuat');
    return;
end

img = app.Result;
sumber = 'hasil saat ini';
if isempty(img)
    img = app.Original;
    sumber = 'citra masukan (belum ada hasil)';
end

try
    name = tempProcess('save', img);
catch ex
    uialert(app.Figure, sprintf('%s\n\n%s', ex.message, ...
        'Periksa folder dataset dan hak tulis.'), 'Gagal menyimpan ke temp');
    return;
end

refreshOperandList(app);
app.LogText.Value = [app.LogText.Value(:); {sprintf('Disimpan ke temp: %s (%s)', name, sumber)}];
end

function onClearTemp(app)
names = tempProcess('list');
if isempty(names)
    uialert(app.Figure, 'Folder temp sudah kosong.', 'Kosongkan Temp', 'Icon', 'info');
    return;
end

pilihan = uiconfirm(app.Figure, ...
    sprintf('Hapus %d citra di %s?', numel(names), tempProcess('folder')), ...
    'Kosongkan Temp', 'Options', {'Hapus', 'Batal'}, ...
    'DefaultOption', 'Batal', 'CancelOption', 'Batal', 'Icon', 'warning');
if ~strcmp(pilihan, 'Hapus')
    return;
end

tempProcess('clear');
refreshOperandList(app);
end

function label = originalOperandLabel()
label = '[Citra masukan asli]';
end

function label = currentResultLabel()
label = '[Hasil saat ini]';
end

function refreshOperandList(app)
% samakan daftar pilihan kedua citra dengan isi folder temp; pilihan lama dipertahankan kalau masih ada
temp = tempProcess('list');
itemsImg = [{currentResultLabel(), originalOperandLabel()}, temp];
itemsOp  = [{originalOperandLabel(), currentResultLabel()}, temp];

curImg = app.ArithImage.Value;
curOp  = app.ArithOperand.Value;
app.ArithImage.Items   = itemsImg;
app.ArithOperand.Items = itemsOp;
if any(strcmp(curImg, itemsImg)), app.ArithImage.Value = curImg; else, app.ArithImage.Value = itemsImg{1}; end
if any(strcmp(curOp, itemsOp)),   app.ArithOperand.Value = curOp; else, app.ArithOperand.Value = itemsOp{1}; end
updateOperandInfo(app);
end

function updateOperandInfo(app)
% tampilkan ukuran kedua citra dan tandai kalau tidak cocok satu sama lain
[ok1, sz1, ch1] = sourceInfo(app, app.ArithImage.Value);
[ok2, sz2, ch2] = sourceInfo(app, app.ArithOperand.Value);

if ~ok1 || ~ok2
    if isempty(app.Original)
        app.ArithInfo.Text = 'Muat citra dulu.';
        app.ArithInfo.FontColor = [0.3 0.3 0.3];
    else
        app.ArithInfo.Text = 'Berkas tidak terbaca. Kosongkan temp atau simpan ulang.';
        app.ArithInfo.FontColor = [0.7 0.1 0.1];
    end
    return;
end

msg = sprintf('Citra 1: %dx%d, %s | Citra 2: %dx%d, %s', ...
    sz1(1), sz1(2), channelName(ch1), sz2(1), sz2(2), channelName(ch2));
if any(sz1 ~= sz2) || ch1 ~= ch2
    msg = [msg '. TIDAK COCOK, operasi akan ditolak.'];
    app.ArithInfo.FontColor = [0.7 0.1 0.1];
else
    app.ArithInfo.FontColor = [0.2 0.2 0.2];
end
app.ArithInfo.Text = msg;
end

function [ok, sz, nCh] = sourceInfo(app, sel)
% ukuran dan jumlah kanal sumber tanpa membaca seluruh piksel (file temp lewat imfinfo)
ok = false; sz = [0 0]; nCh = 0;
try
    if any(strcmp(sel, {originalOperandLabel(), currentResultLabel()}))
        % hasil selalu berukuran sama dengan citra masukan
        if isempty(app.Original), return; end
        sz = [size(app.Original, 1), size(app.Original, 2)];
        nCh = size(app.Original, 3);
    else
        info = imfinfo(fullfile(tempProcess('folder'), sel));
        sz = [info.Height, info.Width];
        nCh = 1 + 2 * strcmpi(info.ColorType, 'truecolor');
    end
    ok = true;
catch
    ok = false;
end
end

function t = channelName(nCh)
if nCh == 3
    t = 'RGB';
else
    t = 'abu-abu';
end
end

function [img, name] = readSource(app, sel)
% baca citra untuk dropdown Citra 1 / Citra 2
if strcmp(sel, originalOperandLabel())
    img = app.Original;
    name = 'citra masukan asli';
    return;
end

if strcmp(sel, currentResultLabel())
    if isempty(app.Result)
        img = app.Original;
        name = 'citra masukan asli (belum ada hasil)';
    else
        img = app.Result;
        name = 'hasil saat ini';
    end
    return;
end

filePath = fullfile(tempProcess('folder'), sel);
if ~isfile(filePath)
    refreshOperandList(app);
    error('Berkas "%s" sudah tidak ada. Daftar pilihan sudah disegarkan, pilih lagi.', sel);
end
try
    img = imread(filePath);
catch ex
    error('Berkas "%s" tidak bisa dibaca: %s', sel, ex.message);
end
name = sel;
end

function onSaveRecord(app)
if isempty(app.Original)
    uialert(app.Figure, 'Muat citra dulu sebelum menyimpan rekapan.', ...
        'Citra belum dimuat');
    return;
end

try
    rec = buildRecord(app);
    writeCsv(app, rec);
    app.RefStatus.FontColor = [0.2 0.5 0.2];
    uialert(app.Figure, sprintf('Rekapan disimpan ke:\\n%s', ...
        fullfile(app.OutFolder, 'rekapan.csv')), 'Tersimpan', 'Icon', 'success');
catch ex
    uialert(app.Figure, sprintf('%s\\n\\n%s', ex.message, ...
        'Periksa folder tujuan dan hak tulis.'), 'Rekapan gagal disimpan');
end
end

function closeApp(fig, app)
delete(fig);
delete(app.Reference);
app.Original = [];
app.Result   = [];
end

% ===========================================================================
% Pembacaan input & penyegaran tampilan
% ===========================================================================

function [tech, params] = collectInputs(app)

switch app.TechBox.Value
    case 'Intensity Transformation'
        tech = 'intensity';
        params = struct( ...
            'mode',  app.IntensityMode.Value, ...
            'c',     app.IntensityC.Value, ...
            'gamma', app.IntensityGamma.Value, ...
            'r1',    app.IntensityR1.Value, ...
            'r2',    app.IntensityR2.Value, ...
            's1',    app.IntensitySMin.Value, ...
            's2',    app.IntensitySMax.Value, ...
            'r1rgb', arrayfun(@(f) f.Value, app.IntensityRGBIn(:, 1))', ...
            'r2rgb', arrayfun(@(f) f.Value, app.IntensityRGBIn(:, 2))', ...
            's1rgb', arrayfun(@(f) f.Value, app.IntensityRGBOut(:, 1))', ...
            's2rgb', arrayfun(@(f) f.Value, app.IntensityRGBOut(:, 2))');

    case 'Histogram Equalization'
        tech = 'equalization';
        params = struct('variant', app.EqualVariant.Value);

    case 'Histogram Specification / Matching'
        tech = 'specification';
        params = struct('reference', app.Reference);

    case 'Image Filtering'
        tech = 'filtering';
        params = struct();

        if strcmp(app.FilterType.Value, 'median')
            params.jenis      = 'median';
            params.windowSize = app.FilterParam2.Value;
        else
            params.jenis        = 'linear';
            params.kernelSource = app.KernelSource.Value;
            params.kernelSize   = str2double(app.KernelSize.Value);

            normalize = app.NormalizeKernel.Value;
            if strcmp(app.KernelSource.Value, 'custom') || ~normalize
                params.kernelSource    = 'custom';
                params.kernel          = app.KernelTable.Data;
                params.normalizeKernel = normalize;
            elseif strcmp(app.KernelSource.Value, 'gaussian')
                params.sigma = app.FilterParam1.Value;
            elseif strcmp(app.KernelSource.Value, 'sharpen')
                params.sharpWeight = app.FilterParam1.Value;
            end
        end

    case 'Image Arithmetic'
        tech = 'arithmetic';
        [img1, name1] = readSource(app, app.ArithImage.Value);
        [img2, name2] = readSource(app, app.ArithOperand.Value);
        params = struct( ...
            'operation',   app.ArithOperation.Value, ...
            'image',       img1, ...
            'imageName',   name1, ...
            'operand',     img2, ...
            'operandName', name2);

    otherwise
        error('applyEnhancement:teknikTidakDikenal', ...
            'Teknik tidak dikenal: %s', app.TechBox.Value);
end
end

function refreshAll(app)
drawInputColumn(app);
drawOutputColumn(app);
updateStatsTable(app);
end

function drawInputColumn(app)
if isempty(app.Original)
    clearAxes(app.AxImageIn);  clearAxes(app.AxHistIn);
    clearAxes(app.AxChIn);
    return;
end

isColor = (size(app.Original, 3) == 3);
drawImageAndHistograms( ...
    app.AxImageIn, app.AxHistIn, pickChannels(app.AxChIn, isColor), ...
    app.Original, 'masukan', [0.25 0.25 0.25]);

% judul grayscale di kolom masukan haris sama dengan kolom hasil
title(app.AxHistIn, 'Histogram Abu-abu - Masukan');
applyHistMode(app.AxChIn, app.Original, app.HistMode.Value);
end

function drawOutputColumn(app)
if isempty(app.Result)
    clearAxes(app.AxImageOut); clearAxes(app.AxHistOut); clearAxes(app.AxChOut);
    title(app.AxHistOut, 'Histogram Abu-abu - Hasil');
    return;
end

isColor = (size(app.Result, 3) == 3);
drawImageAndHistograms( ...
    app.AxImageOut, app.AxHistOut, pickChannels(app.AxChOut, isColor), ...
    app.Result, 'hasil', [0.25 0.25 0.25]);
title(app.AxHistOut, 'Histogram Abu-abu - Hasil');
applyHistMode(app.AxChOut, app.Result, app.HistModeOut.Value);
end

function onHistModeChanged(app, mode)
app.HistMode.Value    = mode;
app.HistModeOut.Value = mode;
applyHistMode(app.AxChIn,  app.Original, mode);
applyHistMode(app.AxChOut, app.Result,   mode);
end

function applyHistMode(axCh, img, mode)
% gambar ulang histogram RGB sesuai pilihan dropdown (terpisah / gabungan)
if isempty(img) || size(img, 3) ~= 3
    return;
end

combined = strcmp(mode, 'combined');
warna = {'r', 'g', 'b'};
nama  = {'R', 'G', 'B'};

for k = 1:3
    resetAxes(axCh(k));
end

if combined
    axCh(1).Layout.Column = [1 3];
    showAxes(axCh(1));
    hold(axCh(1), 'on');
    for k = 1:3
        h = computeHistogram(img(:, :, k));
        plot(axCh(1), 0:255, h, 'Color', warna{k}, 'LineWidth', 1.2, ...
            'DisplayName', nama{k});
    end
    hold(axCh(1), 'off');
    title(axCh(1), 'Histogram RGB Gabungan');
    xlabel(axCh(1), 'Intensitas'); ylabel(axCh(1), 'Jumlah Piksel');
    xlim(axCh(1), [0 255]);
    legend(axCh(1), 'show');
    hideAxes(axCh(2));
    hideAxes(axCh(3));
else
    axCh(1).Layout.Column = 1;
    for k = 1:3
        h = computeHistogram(img(:, :, k));
        showAxes(axCh(k));
        bar(axCh(k), 0:255, h, warna{k});
        title(axCh(k), ['Kanal ' nama{k}]);
        xlabel(axCh(k), 'Intensitas'); ylabel(axCh(k), 'Jumlah Piksel');
    end
end
end

function resetAxes(ax)
legend(ax, 'off');
cla(ax);
title(ax, ''); xlabel(ax, ''); ylabel(ax, '');
end

function showAxes(ax)
ax.Visible = 'on';
ax.Toolbar.Visible = 'on';
end

function hideAxes(ax)
% Visible off saja menyisakan toolbar (menu 3 titik), jadi toolbar ikut dimatikan
ax.Visible = 'off';
ax.Toolbar.Visible = 'off';
end

function ax = pickChannels(allAxes, isColor)
if isColor
    ax = allAxes;
else
    ax = [];
end
end

function updateStatsTable(app)
if isempty(app.Original)
    app.StatsTable.Data = {};
    app.StatsTable.ColumnName = {'Fitur', 'Masukan', 'Hasil'};
    return;
end

sb = imageStatistics(app.Original);
colMasukan = statsColumn(sb, sb.isColor);

if isempty(app.Result)
    colHasil = repmat({'-'}, 7, 1);
else
    colHasil = statsColumn(imageStatistics(app.Result), sb.isColor);
end

names = {'Min intensitas', 'Maks intensitas', 'Rerata', ...
         'Simpangan baku', 'Entropi (bit)', ...
         'Min per kanal R,G,B', 'Maks per kanal R,G,B'};

app.StatsTable.ColumnName = {'Fitur', 'Masukan', 'Hasil'};
app.StatsTable.Data = [names(:), colMasukan(:), colHasil(:)];
end

function col = statsColumn(s, showChannels)
% satu kolom tabel fitur; baris kanal diisi '-' kalau citra abu-abu
col = { ...
    num2str(s.grayscale.min), ...
    num2str(s.grayscale.max), ...
    sprintf('%.2f', s.grayscale.mean), ...
    sprintf('%.2f', s.grayscale.std), ...
    sprintf('%.4f', s.entropy), ...
    '-', '-'};
if showChannels && s.isColor
    col{6} = sprintf('%d,%d,%d', s.channels(1).min, s.channels(2).min, s.channels(3).min);
    col{7} = sprintf('%d,%d,%d', s.channels(1).max, s.channels(2).max, s.channels(3).max);
end
end

function setEmptyState(app)
app.Original = [];
app.Result   = [];
app.Steps    = {};
resetHistory(app);

if isfield(app, 'LogText') && ~isempty(app.LogText)
    app.LogText.Value = {'Muat citra dulu, lalu pilih teknik enhancement.'};
    app.StatsTable.Data = {};
    clearAxes(app.AxImageIn);  clearAxes(app.AxHistIn);  clearAxes(app.AxChIn);
    clearAxes(app.AxImageOut); clearAxes(app.AxHistOut); clearAxes(app.AxChOut);
    setRowVisible(app.ChInPanel.Parent, 3, false);
    setRowVisible(app.ChOutPanel.Parent, 3, false);
end
end

function setRowVisible(grid, row, visible)
if ~visible
    grid.RowHeight{row} = 1;
else
    grid.RowHeight{row} = '1x';
end
end

% ---------------------------------------------------------------------------
function setPanelRowVisible(app, panelName, visible)
% Lipat/buka baris pada ParamStack milik panel teknik dengan nama panelName.
% Baris diambil dari Layout.Row panel itu sendiri supaya nomor baris tidak
% di-hardcode di dua tempat.
setRowVisible(app.ParamStack, app.Panels.(panelName).Layout.Row, visible);
end

function clearAxes(ax)
if isempty(ax), return; end
if isgraphics(ax)
    cla(ax);
    axis(ax, 'off');
end
end

% ===========================================================================
% Rekaman (untuk laporan)
% ===========================================================================

function rec = buildRecord(app)
[tech, params] = collectInputs(app);

if ~isempty(app.Result)
    try
        [~, methodName, paramText] = applyEnhancement( ...
            app.Result, tech, params);
    catch
        methodName = '';
        paramText  = '';
    end
else
    methodName = '(belum dijalankan)';
    paramText  = '(belum dijalankan)';
end

folder = app.FolderBox.Value;
k = find(strcmp({app.DatasetIdx.folder}, folder), 1);

rec = struct();
rec.waktu   = char(datetime("now", 'Format', 'yyyy-MM-dd HH:mm:ss'));
rec.folder  = folder;
rec.file    = app.ImageBox.Value;
rec.teknik  = tech;
rec.metode  = methodName;
rec.param   = paramText;

sb = imageStatistics(app.Original);
rec.minSebelum   = sb.grayscale.min;
rec.maksSebelum  = sb.grayscale.max;
rec.rerataSebelum= sb.grayscale.mean;
rec.stdSebelum   = sb.grayscale.std;
rec.entroSebelum = sb.entropy;

if ~isempty(app.Result)
    sa = imageStatistics(app.Result);
    rec.minSesudah   = sa.grayscale.min;
    rec.maksSesudah  = sa.grayscale.max;
    rec.rerataSesudah= sa.grayscale.mean;
    rec.stdSesudah   = sa.grayscale.std;
    rec.entroSesudah = sa.entropy;
else
    rec.minSesudah   = '';
    rec.maksSesudah  = '';
    rec.rerataSesudah= '';
    rec.stdSesudah   = '';
    rec.entroSesudah = '';
end

rec.jumlahLangkah = numel(app.Steps);
rec.langkah       = strjoin(app.Steps, ' ; ');
rec.catatan       = app.NoteText.Value{1};
rec.path          = '';
if ~isempty(k)
    rec.path = fullfile(app.DatasetIdx(k).path, app.ImageBox.Value);
end
end

function writeCsv(app, rec)
if ~isfolder(app.OutFolder)
    mkdir(app.OutFolder);
end

csvPath = fullfile(app.OutFolder, 'rekapan.csv');

header = {'waktu','folder','file','path','teknik','metode','parameter', ...
          'jumlahLangkah','langkah', ...
          'minSebelum','maksSebelum','rerataSebelum','stdSebelum','entroSebelum', ...
          'minSesudah','maksSesudah','rerataSesudah','stdSesudah','entroSesudah', ...
          'catatan'};

row = {rec.waktu, rec.folder, rec.file, rec.path, rec.teknik, rec.metode, rec.param, ...
       num2str(rec.jumlahLangkah), rec.langkah, ...
       fmtNum(rec.minSebelum), fmtNum(rec.maksSebelum), ...
       fmtNum(rec.rerataSebelum), fmtNum(rec.stdSebelum), fmtNum(rec.entroSebelum), ...
       fmtNum(rec.minSesudah), fmtNum(rec.maksSesudah), ...
       fmtNum(rec.rerataSesudah), fmtNum(rec.stdSesudah), fmtNum(rec.entroSesudah), ...
       rec.catatan};

appendRecordCsv(csvPath, header, row);
end

function s = fmtNum(v)
if isempty(v)
    s = '';
elseif isnumeric(v)
    s = sprintf('%.4f', v);
else
    s = char(v);
end
end

function tip = techniqueTooltip(tech)
switch tech
    case 'Intensity Transformation'
        tip = 'Perbaikan intensitas: negative, log, power (gamma), atau contrast stretching.';
    case 'Histogram Equalization'
        tip = 'Meratakan histogram agar kontras lebih optimal.';
    case 'Histogram Specification / Matching'
        tip = 'Menyesuaikan histogram citra dengan citra referensi.';
    case 'Image Filtering'
        tip = 'Filter linear (konvolusi) atau non-linear (median).';
    case 'Image Arithmetic'
        tip = 'Tambah/kurang dua citra berukuran sama, masing-masing dipilih dari hasil saat ini, citra asli, atau hasil yang disimpan ke temp.';
    otherwise
        tip = '';
end
end

% ===========================================================================
% Draggable Divider
% ===========================================================================

function updatePanelPositions(app)
% Perbarui posisi panel kiri, kanan, dan divider berdasarkan DividerPos
    figPos = app.Figure.Position;
    margin = 8 / figPos(3);  % margin dalam normalized units
    dividerWidth = 6 / figPos(3);  % lebar divider dalam normalized units
    gap = 4 / figPos(3);  % gap antar panel dan divider

    divX = app.DividerPos;

    % Left panel: dari kiri ke sebelum divider
    app.LeftPanel.Position = [margin, margin, divX - margin - gap - dividerWidth, 1 - 2*margin];

    % Divider: tepat di posisi divider
    app.Divider.Position = [divX - dividerWidth/2, 0, dividerWidth, 1];

    % Right panel: dari setelah divider ke kanan
    app.RightPanel.Position = [divX + dividerWidth/2 + gap, margin, 1 - divX - dividerWidth/2 - gap - margin, 1 - 2*margin];
end

function setupDividerCallbacks(app)
% Setup mouse callbacks untuk drag divider
    app.Figure.WindowButtonDownFcn   = @(~, ~) onDividerMouseDown(app);
    app.Figure.WindowButtonMotionFcn  = @(~, ~) onDividerMouseMove(app);
    app.Figure.WindowButtonUpFcn      = @(~, ~) onDividerMouseUp(app);
    app.Figure.SizeChangedFcn         = @(~, ~) updatePanelPositions(app);
end

function onDividerMouseDown(app)
% Cek apakah klik mouse dekat dengan divider
    figPos = app.Figure.Position;
    mouseX = app.Figure.CurrentPoint(1);  % posisi X mouse dalam pixel
    dividerPixelX = figPos(3) * app.DividerPos;

    % Toleransi 10 pixel
    if abs(mouseX - dividerPixelX) < 10
        app.IsDragging = true;
        app.Figure.Pointer = 'left';  % cursor resize
    end
end

function onDividerMouseMove(app)
% Update posisi divider saat dragging
    if app.IsDragging
        figPos = app.Figure.Position;
        mouseX = app.Figure.CurrentPoint(1);

        % Konversi ke posisi normalized
        newPos = mouseX / figPos(3);

        % Batasi: minimum 15%, maksimum 60%
        newPos = max(0.15, min(0.60, newPos));

        app.DividerPos = newPos;
        updatePanelPositions(app);
    else
        % Highlight divider saat hover
        figPos = app.Figure.Position;
        mouseX = app.Figure.CurrentPoint(1);
        dividerPixelX = figPos(3) * app.DividerPos;

        if abs(mouseX - dividerPixelX) < 10
            app.Figure.Pointer = 'left';
        else
            app.Figure.Pointer = 'arrow';
        end
    end
end

function onDividerMouseUp(app)
% Selesai dragging
    app.IsDragging = false;
    app.Figure.Pointer = 'arrow';
end



