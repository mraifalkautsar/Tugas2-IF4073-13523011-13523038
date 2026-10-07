function appendRecordCsv(csvPath, header, row)
% Tambah satu baris ke berkas rekap CSV

% csvPath: path lengkap file CSV tujuan, contoh 'out/rekapan.csv'
% header: nama kolom, hanya apabila kalau file belum ada
% row: nilai baris baru, urutannya harus sama dengan header

validateattributes(csvPath, {'char', 'string'}, {'nonempty'}, ...
    'appendRecordCsv', 'csvPath');

if ~iscell(header) || ~iscell(row)
    error('appendRecordCsv:argBukanCell', 'header dan row harus berupa cell array.');
end

if numel(row) ~= numel(header)
    error('appendRecordCsv:jumlahKolomTidakCocok', ...
        'Jumlah nilai baris (%d) tidak sama dengan jumlah kolom (%d).', ...
        numel(row), numel(header));
end

folder = fileparts(csvPath);
if ~isempty(folder) && ~isfolder(folder)
    mkdir(folder);
end

isNew = ~isfile(csvPath);

fid = fopen(csvPath, 'a', 'n', 'UTF-8');
if fid < 0
    error('appendRecordCsv:tidakBisaDitulis', ...
        'Tidak bisa menulis ke berkas: %s', csvPath);
end

cleanupFid = onCleanup(@() fclose(fid));

if isNew
    fwrite(fid, strjoin(csvEscape(header), ','), 'char');
    fwrite(fid, newlineString(), 'char');
end

fwrite(fid, strjoin(csvEscape(row), ','), 'char');
fwrite(fid, newlineString(), 'char');
end

% ---------------------------------------------------------------------------
function out = csvEscape(cellValues)
% Beri tanda kutip pada nilai yang mengandung koma atau kutip, ikut RFC 4180
out = cell(size(cellValues));
for k = 1:numel(cellValues)
    v = cellValues{k};
    if isnumeric(v)
        v = num2str(v);
    elseif islogical(v)
        v = char(string(v));
    elseif (isstring(v) && numel(v) ~= 1)
        v = '';
    end
    v = char(v);

    butuhKutip = contains(v, ',') || contains(v, '"') || ...
        contains(v, newline);
    if butuhKutip
        v = ['"' strrep(v, '"', '""') '"'];
    end
    out{k} = v;
end
end

% ---------------------------------------------------------------------------
function nl = newlineString()
% Newline LF biar keluaran konsisten di semua OS
nl = newline;
end
