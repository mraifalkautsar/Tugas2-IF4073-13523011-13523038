function app = FrequencyProcessingApp()
%FREQUENCYPROCESSINGAPP Single GUI for IF4073 Tugas 2 (B--F).
% Sections B/C run frequency-domain filters; D--F remain placeholders.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src', 'frequency'));
datasetRoot = fullfile(root, 'dataset');
index = datasetIndex(datasetRoot);
inputImage = [];
referenceImage = [];
parameterFields = struct();
paramGrid = [];
orderLabel = [];

app = uifigure('Name', 'IF4073 Tugas 2 - Ranah Frekuensi', ...
    'Position', [90 60 1320 780], 'Visible', 'off');
main = uigridlayout(app, [1 2]);
main.ColumnWidth = {340, '1x'};
main.Padding = [10 10 10 10];
main.ColumnSpacing = 10;

left = uipanel(main, 'Title', 'Kontrol');
controls = uigridlayout(left, [11 1]);
controls.RowHeight = {24, 28, 28, 22, 110, 28, 28, 22, '1x', 28, 60};
controls.RowSpacing = 5;
controls.Padding = [8 8 8 8];

uilabel(controls, 'Text', 'Bagian tugas', 'FontWeight', 'bold');
sectionBox = uidropdown(controls, 'Items', { ...
    'B - Low-pass / smoothing', 'C - High-pass', ...
    'D - Peningkatan kecerahan', 'E - Derau periodik', ...
    'F - Motion blur'}, 'ItemsData', {'B', 'C', 'D', 'E', 'F'}, ...
    'Value', 'B', 'ValueChangedFcn', @(~, ~) sectionChanged());
uibutton(controls, 'Text', 'Pilih Folder Dataset...', ...
    'ButtonPushedFcn', @(~, ~) chooseDataset());
uilabel(controls, 'Text', 'Input pada bagian terpilih', 'FontWeight', 'bold');
imageList = uilistbox(controls, 'Items', {'(dataset belum tersedia)'}, ...
    'Enable', 'off');

fileButtons = uigridlayout(controls, [1 2]);
fileButtons.ColumnWidth = {'1x', '1x'};
fileButtons.Padding = [0 0 0 0];
uibutton(fileButtons, 'Text', 'Muat Input', ...
    'ButtonPushedFcn', @(~, ~) loadDatasetImage());
uibutton(fileButtons, 'Text', 'Buka File...', ...
    'ButtonPushedFcn', @(~, ~) openImage(false));

uibutton(controls, 'Text', 'Buka Referensi... (opsional)', ...
    'ButtonPushedFcn', @(~, ~) openImage(true));
uilabel(controls, 'Text', 'Parameter metode', ...
    'FontWeight', 'bold');
parameterPanel = uipanel(controls, 'Title', 'Parameter bagian B');
processButton = uibutton(controls, 'Text', 'Terapkan filter', ...
    'Enable', 'off', 'ButtonPushedFcn', @(~, ~) processImage());
status = uitextarea(controls, 'Editable', 'off', 'Value', { ...
    'Pilih citra, jenis penapis, dan parameter.', ...
    'Bagian D-F belum diimplementasikan.'});

right = uigridlayout(main, [3 2]);
right.RowHeight = {'1x', '1x', '1x'};
right.ColumnWidth = {'1x', '1x'};
right.RowSpacing = 7;
right.ColumnSpacing = 7;
right.Padding = [0 0 0 0];
panels = gobjects(1, 6);
axesHandles = gobjects(1, 6);
for k = 1:6
    panels(k) = uipanel(right, 'Title', '');
    panels(k).Layout.Row = ceil(k / 2);
    panels(k).Layout.Column = mod(k - 1, 2) + 1;
    cellGrid = uigridlayout(panels(k), [2 1]);
    cellGrid.RowHeight = {'1x', 26};
    cellGrid.Padding = [2 2 2 2];
    axesHandles(k) = uiaxes(cellGrid);
    axesHandles(k).XTick = [];
    axesHandles(k).YTick = [];
    axesHandles(k).UserData = uibutton(cellGrid, 'Text', 'Layar penuh', ...
        'Enable', 'off', 'ButtonPushedFcn', @(~, ~) openFullScreen(k));
end

sectionChanged();
app.Visible = 'on';

    function openFullScreen(k)
        source = axesHandles(k);
        content = findobj(source, 'Type', 'image');
        if isempty(content), return; end
        viewer = uifigure('Name', panels(k).Title, 'Tag', 'FullScreenView', ...
            'Visible', 'off', ...
            'KeyPressFcn', @closeOnEscape);
        layout = uigridlayout(viewer, [2 1]);
        layout.RowHeight = {28, '1x'};
        uibutton(layout, 'Text', 'Tutup (Esc)', ...
            'ButtonPushedFcn', @(~, ~) delete(viewer));
        enlarged = uiaxes(layout);
        copyobj(content, enlarged);
        colormap(enlarged, colormap(source));
        enlarged.YDir = source.YDir;
        axis(enlarged, 'image');
        axis(enlarged, 'off');
        enlarged.CLim = source.CLim;
        viewer.Visible = 'on';
        drawnow;
        viewer.WindowState = 'fullscreen';
    end

    function sectionChanged()
        inputImage = [];
        referenceImage = [];
        processButton.Enable = 'off';
        section = sectionBox.Value;
        sectionNumber = double(section) - double('A');
        paths = index(sectionNumber).input;
        if isempty(paths)
            imageList.Items = {'(tidak ada citra input)'};
            imageList.Enable = 'off';
        else
            labels = cellfun(@fileLabel, paths, 'UniformOutput', false);
            imageList.Items = labels;
            imageList.Value = labels{1};
            imageList.Enable = 'on';
        end
        parameterPanel.Title = ['Parameter bagian ' section];
        buildParameters(section);
        if strcmp(section, 'F')
            titles = {'Citra terdegradasi', 'Spektrum sebelum', ...
                'PSF / fungsi degradasi', 'Referensi (opsional)', ...
                'Inverse filtering (belum ada)', 'Wiener filtering (belum ada)'};
        elseif any(section == 'BC')
            titles = {'Citra masukan', 'Spektrum sebelum (log)', ...
                'Fungsi penapis H(u,v)', 'Spektrum setelah (log)', ...
                'Citra hasil', 'Referensi (opsional)'};
        else
            titles = {'Citra input / terdegradasi', 'Spektrum sebelum', ...
                'Mask / transfer H(u,v) (belum ada)', 'Spektrum setelah (belum ada)', ...
                'Citra hasil (belum ada)', 'Referensi (opsional)'};
        end
        for j = 1:6
            panels(j).Title = titles{j};
            showPlaceholder(axesHandles(j), 'Belum tersedia');
        end
        if any(section == 'BC')
            note = 'Muat citra, lalu tekan Terapkan filter.';
        else
            note = 'Metode bagian ini belum diimplementasikan.';
        end
        status.Value = {sprintf('Bagian %s: %d citra input ditemukan.', ...
            section, numel(paths)), note};
    end

    function buildParameters(section)
        delete(parameterPanel.Children);
        parameterFields = struct();
        paramGrid = uigridlayout(parameterPanel, [7 2]);
        paramGrid.RowHeight = repmat({28}, 1, 7);
        paramGrid.ColumnWidth = {130, '1x'};
        paramGrid.RowSpacing = 7;
        paramGrid.Padding = [8 8 8 8];
        switch section
            case 'B'
                addChoice('Low-pass', {'Ideal', 'Gaussian', 'Butterworth'});
                addNumber('Cutoff D0', 30);
                orderLabel = addNumber('Order (Butterworth)', 2);
                parameterFields.field2.Limits = [eps Inf];
                parameterFields.field2.Tooltip = 'Cutoff radius in frequency bins';
                parameterFields.field3.Limits = [1 Inf];
                parameterFields.field3.RoundFractionalValues = true;
                parameterFields.field1.ValueChangedFcn = @(~, ~) filterChanged();
                parameterFields.field2.ValueChangedFcn = @(~, ~) parametersChanged();
                parameterFields.field3.ValueChangedFcn = @(~, ~) parametersChanged();
                updateOrderField();
            case 'C'
                addChoice('High-pass', {'Ideal', 'Gaussian', 'Butterworth'});
                addNumber('Cutoff D0', 30);
                orderLabel = addNumber('Order (Butterworth)', 2);
                parameterFields.field2.Limits = [eps Inf];
                parameterFields.field2.Tooltip = 'Cutoff radius in frequency bins';
                parameterFields.field3.Limits = [1 Inf];
                parameterFields.field3.RoundFractionalValues = true;
                parameterFields.field1.ValueChangedFcn = @(~, ~) filterChanged();
                parameterFields.field2.ValueChangedFcn = @(~, ~) parametersChanged();
                parameterFields.field3.ValueChangedFcn = @(~, ~) parametersChanged();
                updateOrderField();
            case 'D'
                addChoice('Strategi', {'Penguatan frekuensi rendah'});
                addNumber('Gain DC / rendah', 1.5);
                addNumber('Cutoff D0', 30);
            case 'E'
                addChoice('Penapis', {'Bandreject Ideal', 'Bandreject Butterworth', ...
                    'Bandreject Gaussian', 'Notch reject'});
                addNumber('Frekuensi pusat D0', 30);
                addNumber('Lebar pita W', 10);
                addNumber('Order (Butterworth)', 2);
                addText('Notch (u,v)', '20,15; -20,-15');
                addNumber('Radius notch', 5);
            case 'F'
                addNumber('Panjang gerak', 15);
                addNumber('Sudut (derajat)', 0);
                addNumber('Batas inverse', 0.01);
                addNumber('Wiener K / NSR', 0.01);
        end
        usedRows = numel(fieldnames(parameterFields));
        paramGrid.RowHeight = [repmat({28}, 1, usedRows), ...
            repmat({'fit'}, 1, 7 - usedRows)];
    end

    function updateOrderField()
        isButterworth = strcmp(parameterFields.field1.Value, 'Butterworth');
        orderLabel.Visible = isButterworth;
        parameterFields.field3.Visible = isButterworth;
    end

    function filterChanged()
        updateOrderField();
        parametersChanged();
    end

    function parametersChanged()
        for j = 3:5
            showPlaceholder(axesHandles(j), 'Terapkan filter untuk melihat hasil');
        end
        panels(5).Title = 'Citra hasil';
        if ~isempty(inputImage)
            status.Value = {'Parameter berubah.', 'Tekan Terapkan filter untuk memperbarui hasil.'};
        end
    end

    function addChoice(label, items)
        row = numel(fieldnames(parameterFields)) + 1;
        lbl = uilabel(paramGrid, 'Text', label);
        lbl.Layout.Row = row;
        lbl.Layout.Column = 1;
        field = uidropdown(paramGrid, 'Items', items);
        field.Layout.Row = row;
        field.Layout.Column = 2;
        parameterFields.(sprintf('field%d', row)) = field;
    end

    function lbl = addNumber(label, value)
        row = numel(fieldnames(parameterFields)) + 1;
        lbl = uilabel(paramGrid, 'Text', label);
        lbl.Layout.Row = row;
        lbl.Layout.Column = 1;
        field = uieditfield(paramGrid, 'numeric', 'Value', value);
        field.Layout.Row = row;
        field.Layout.Column = 2;
        parameterFields.(sprintf('field%d', row)) = field;
    end

    function addText(label, value)
        row = numel(fieldnames(parameterFields)) + 1;
        lbl = uilabel(paramGrid, 'Text', label);
        lbl.Layout.Row = row;
        lbl.Layout.Column = 1;
        field = uieditfield(paramGrid, 'text', 'Value', value);
        field.Layout.Row = row;
        field.Layout.Column = 2;
        parameterFields.(sprintf('field%d', row)) = field;
    end

    function chooseDataset()
        folder = uigetdir(datasetRoot, 'Pilih folder induk dataset B-F');
        if isequal(folder, 0), return; end
        datasetRoot = folder;
        index = datasetIndex(datasetRoot);
        sectionChanged();
    end

    function loadDatasetImage()
        paths = index(double(sectionBox.Value) - double('A')).input;
        if isempty(paths), return; end
        labels = cellfun(@fileLabel, paths, 'UniformOutput', false);
        loadInput(paths{strcmp(labels, imageList.Value)});
    end

    function openImage(isReference)
        [name, folder] = uigetfile({ ...
            '*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'File citra'; ...
            '*.*', 'Semua file'}, 'Pilih citra');
        if isequal(name, 0), return; end
        path = fullfile(folder, name);
        if isReference
            try
                referenceImage = imread(path);
                if strcmp(sectionBox.Value, 'F')
                    showImage(axesHandles(4), referenceImage);
                else
                    showImage(axesHandles(6), referenceImage);
                end
                status.Value = {['Referensi dibuka: ' name], ...
                    'Referensi hanya ditampilkan; belum digunakan untuk pemrosesan.'};
            catch ex
                uialert(app, ex.message, 'Gagal membaca referensi');
            end
        else
            loadInput(path);
        end
    end

    function loadInput(path)
        try
            img = imread(path);
            if ~(ismatrix(img) || (ndims(img) == 3 && size(img, 3) == 3))
                error('Hanya citra grayscale atau RGB yang didukung.');
            end
            spectrum = magnitudeSpectrum(im2double(img));
            inputImage = img;
            panels(5).Title = 'Citra hasil';
            showImage(axesHandles(1), inputImage);
            showMatrix(axesHandles(2), spectrum);
            for j = 3:6
                showPlaceholder(axesHandles(j), 'Belum tersedia');
            end
            if ~isempty(referenceImage)
                if strcmp(sectionBox.Value, 'F')
                    showImage(axesHandles(4), referenceImage);
                else
                    showImage(axesHandles(6), referenceImage);
                end
            end
            if any(sectionBox.Value == 'BC')
                processButton.Enable = 'on';
            end
            [~, name, ext] = fileparts(path);
            status.Value = {sprintf('Input: %s%s (%d x %d x %d)', name, ext, ...
                size(img, 1), size(img, 2), size(img, 3)), ...
                'Spektrum input ditampilkan; pilih filter dan tekan Terapkan.'};
        catch ex
            uialert(app, ex.message, 'Gagal membaca input');
        end
    end

    function processImage()
        if isempty(inputImage) || ~any(sectionBox.Value == 'BC'), return; end
        family = parameterFields.field1.Value;
        cutoff = parameterFields.field2.Value;
        order = parameterFields.field3.Value;
        pass = 'low';
        if strcmp(sectionBox.Value, 'C'), pass = 'high'; end
        try
            [result, H, before, after] = radialFilter(inputImage, ...
                pass, family, cutoff, order);
            showMatrix(axesHandles(2), before);
            showMatrix(axesHandles(3), H, [0 1]);
            scale = max(1, max(before(:)));
            showMatrix(axesHandles(4), after, [0 scale]);
            if strcmp(pass, 'high')
                % The true result has negative values and zero mean; a fixed
                % midpoint (gray = 0 response) shows both edge polarities.
                displayImage = min(max(result + 0.5, 0), 1);
                panels(5).Title = 'Citra hasil (+0.5 untuk tampilan)';
                note = 'HPF mentah bertanda; abu-abu 50% = respons nol.';
            else
                displayImage = min(max(result, 0), 1);
                panels(5).Title = 'Citra hasil (nilai asli, dipotong saat tampil)';
                note = 'Nilai di luar [0,1] hanya dipotong saat tampil.';
            end
            showImage(axesHandles(5), displayImage);
            param = sprintf('%s %s | D0 = %g', family, upper(pass), cutoff);
            if strcmp(family, 'Butterworth')
                param = sprintf('%s | orde = %g', param, order);
            end
            status.Value = {param, note, 'FFT tanpa padding (batas periodik).'};
        catch ex
            uialert(app, ex.message, 'Filter gagal');
        end
    end
end

function label = fileLabel(path)
[~, name, ext] = fileparts(path);
label = [name ext];
end

function showImage(ax, img)
cla(ax);
imshow(img, 'Parent', ax);
ax.UserData.Enable = 'on';
end

function showPlaceholder(ax, message)
cla(ax);
ax.UserData.Enable = 'off';
axis(ax, 'off');
text(ax, 0.5, 0.5, message, 'Units', 'normalized', ...
    'HorizontalAlignment', 'center', 'Color', [0.45 0.45 0.45]);
end

function showMatrix(ax, data, limits)
cla(ax);
imagesc(ax, data);
axis(ax, 'image');
colormap(ax, gray(256));
if nargin == 3, caxis(ax, limits); end
ax.XTick = [];
ax.YTick = [];
ax.UserData.Enable = 'on';
end

function closeOnEscape(viewer, event)
if strcmp(event.Key, 'escape'), delete(viewer); end
end
