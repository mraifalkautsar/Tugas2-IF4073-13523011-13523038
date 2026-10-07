function out = tempProcess(action, varargin)
% tempProcess - kelola folder hasil antara (dataset/tempProcess)
%
%   names = tempProcess('list')          % nama file png terurut abjad ({} kalau kosong)
%   name  = tempProcess('save', img)     % simpan img sebagai proc_NNN.png, kembalikan nama
%           tempProcess('clear')         % hapus semua png di folder ini (tidak rekursif)
%   dir   = tempProcess('folder')        % path folder
%
% Nama file otomatis: nomor terbesar yang sudah ada + 1, jadi tidak pernah menimpa.

folder = fullfile('dataset', 'tempProcess');

switch lower(action)
    case 'folder'
        out = folder;

    case 'list'
        out = listPng(folder);

    case 'save'
        img = varargin{1};
        validateattributes(img, {'uint8'}, {'nonempty'}, 'tempProcess', 'img');
        if ~isfolder(folder)
            mkdir(folder);
        end
        out = sprintf('proc_%03d.png', nextIndex(listPng(folder)));
        imwrite(img, fullfile(folder, out));

    case 'clear'
        names = listPng(folder);
        for k = 1:numel(names)
            delete(fullfile(folder, names{k}));
        end
        out = numel(names);

    otherwise
        error('tempProcess:aksiTidakDikenal', 'Aksi tidak dikenal: %s', action);
end
end

function names = listPng(folder)
if ~isfolder(folder)
    names = {};
    return;
end
files = dir(fullfile(folder, '*.png'));
names = sort({files.name});
end

function n = nextIndex(names)
% angka terbesar dari nama proc_NNN.png yang ada, +1
n = 1;
for k = 1:numel(names)
    tok = regexp(names{k}, '^proc_(\d+)\.png$', 'tokens', 'once');
    if ~isempty(tok)
        n = max(n, str2double(tok{1}) + 1);
    end
end
end
