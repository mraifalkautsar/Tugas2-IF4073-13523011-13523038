function runFrequencyExperiments(mode)
%RUNFREQUENCYEXPERIMENTS Compare every B/C input using the application's filter.
% Run from the repository: startup; addpath('scripts'); runFrequencyExperiments
% C selections are recorded in docs/hpf-recommendations.csv; 'export-hpf'
% exports their complete pipelines and nearby visual comparisons.
% 'refine' reuses the existing sweep and refines both PSNR and SSIM peaks.
% 'hpf' repeats only the HPF comparisons and exports.
if nargin < 1, mode = 'all'; end
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'gui'), fullfile(root, 'src', 'frequency'));
index = datasetIndex(fullfile(root, 'dataset'));
output = fullfile(root, 'out', 'frequency-experiments');
if ~isfolder(output), mkdir(output); end
if strcmp(mode, 'export-hpf')
    selected = readtable(fullfile(root, 'docs', 'hpf-recommendations.csv'));
    refined = cell(0, 6);
    for k = 1:height(selected)
        filename = char(string(selected.File(k)));
        img = imread(fullfile(index(2).folder, 'input', filename));
        [~, name] = fileparts(filename);
        folder = fullfile(output, 'C', name);
        views = {im2double(img)}; labels = {'Original input'};
        choices = {'Ideal', 2; 'Gaussian', 2; 'Butterworth', 1; 'Butterworth', 2; 'Butterworth', 4};
        for c = 1:size(choices, 1)
            for cutoff = unique(max(1, round(selected.D0(k) * [.75 1 1.25])))
                result = radialFilter(img, 'high', choices{c,1}, cutoff, choices{c,2});
                views{end+1} = min(max(result + .5, 0), 1); %#ok<AGROW>
                labels{end+1} = filterLabel(choices{c,1}, cutoff, choices{c,2}); %#ok<AGROW>
                refined(end+1,:) = {filename, choices{c,1}, cutoff, choices{c,2}, ...
                    sqrt(mean(result(:).^2)), 100 * mean(abs(result(:)) > .5)}; %#ok<AGROW>
            end
        end
        comparison(views, labels, [4 4], [name ' - HPF cutoff refinement'], fullfile(folder, 'refinement.png'));
        comparison(cellfun(@(x) detail(x, name), views, 'UniformOutput', false), ...
            labels, [4 4], [name ' - HPF refinement detail'], fullfile(folder, 'refinement_detail.png'));
        exportPipeline(img, [], 'high', char(string(selected.Family(k))), ...
            selected.D0(k), selected.Order(k), fullfile(output, 'C', name, 'selected'));
    end
    writetable(selected, fullfile(output, 'hpf_recommendations.csv'));
    writetable(cell2table(refined, 'VariableNames', ...
        {'File', 'Family', 'D0', 'Order', 'ResponseRMS', 'DisplayClippedPercent'}), ...
        fullfile(output, 'hpf_refined_results.csv'));
    fprintf('Exported %d selected HPF pipelines.\n', height(selected));
    return;
end

configs = {'Ideal', 2; 'Gaussian', 2; 'Butterworth', 1; ...
    'Butterworth', 2; 'Butterworth', 3; 'Butterworth', 4; ...
    'Butterworth', 5; 'Butterworth', 6};
columns = {'File', 'Family', 'D0', 'Order', 'Stage', 'PSNR', 'SSIM', 'OutsideRangePercent'};
allResults = cell2table(cell(0, 8), 'VariableNames', columns);
baseline = cell(0, 3);
familyBest = allResults;
selected = allResults;
bestSsim = allResults;
if strcmp(mode, 'refine')
    previous = readtable(fullfile(output, 'lpf_all_results.csv'));
end
inputs = index(1).input;
if strcmp(mode, 'hpf'), inputs = {}; end
for k = 1:numel(inputs)
    path = inputs{k};
    [~, name, ext] = fileparts(path);
    referenceName = regexprep(name, '_gaussian_noise$', '');
    img = imread(path);
    reference = im2double(imread(fullfile(index(1).folder, 'reference', [referenceName ext])));
    assert(isequal(size(img), size(reference)), 'Input/reference dimensions differ: %s', name);
    [p, s] = quality(im2double(img), reference);
    baseline(end + 1, :) = {[name ext], p, s}; %#ok<AGROW>
    shortSide = min(size(img, 1), size(img, 2));
    cutoffs = unique([max(1, round(shortSide * ...
        [.01 .015 .02 .03 .04 .06 .08 .10 .14 .18 .24 .32 .45 .60 .80])), ...
        ceil(hypot(floor(size(img, 1)/2), floor(size(img, 2)/2)))]);
    rows = cell(0, 8);
    if strcmp(mode, 'refine')
        rows = table2cell(previous(strcmp(previous.File, [name ext]), :));
    end
    for c = 1:size(configs, 1)
        family = configs{c, 1}; order = configs{c, 2};
        coarse = rows(strcmp(rows(:,2), family) & cell2mat(rows(:,4)) == order, :);
        if isempty(coarse)
            for cutoff = cutoffs
                coarse(end + 1, :) = evaluate(img, reference, [name ext], family, cutoff, order, 'coarse'); %#ok<AGROW>
            end
            rows = [rows; coarse]; %#ok<AGROW>
        end
        [~, bestP] = max(cell2mat(coarse(:, 6)));
        [~, bestS] = max(cell2mat(coarse(:, 7)));
        fine = [];
        for center = [coarse{bestP,3}, coarse{bestS,3}]
            fine = [fine, max(1, round(linspace(center * .75, center * 1.25, 13)))]; %#ok<AGROW>
            fine = [fine, max(1, center + (-5:5))]; %#ok<AGROW>
        end
        fine = setdiff(unique(fine), cell2mat(coarse(:,3))');
        for cutoff = fine
            rows(end + 1, :) = evaluate(img, reference, [name ext], family, cutoff, order, 'refine'); %#ok<AGROW>
        end
    end
    results = cell2table(rows, 'VariableNames', columns);
    allResults = [allResults; results]; %#ok<AGROW>
    bestRows = results([],:);
    for family = {'Ideal', 'Gaussian', 'Butterworth'}
        candidates = results(strcmp(results.Family, family{1}), :);
        [~, best] = max(candidates.PSNR);
        bestRows = [bestRows; candidates(best,:)]; %#ok<AGROW>
    end
    familyBest = [familyBest; bestRows]; %#ok<AGROW>
    [~, best] = max(results.PSNR);
    selected = [selected; results(best,:)]; %#ok<AGROW>
    [~, best] = max(results.SSIM);
    bestSsim = [bestSsim; results(best,:)]; %#ok<AGROW>
    folder = fullfile(output, 'B', name);
    if ~isfolder(folder), mkdir(folder); end
    views = {im2double(img), reference};
    labels = {sprintf('Input\nPSNR %.2f | SSIM %.4f', p, s), 'Reference'};
    for c = 1:height(bestRows)
        r = bestRows(c,:);
        views{end + 1} = radialFilter(img, 'low', r.Family{1}, r.D0, r.Order); %#ok<AGROW>
        labels{end + 1} = settingLabel(r, true); %#ok<AGROW>
    end
    r = bestSsim(end,:);
    views{end + 1} = radialFilter(img, 'low', r.Family{1}, r.D0, r.Order);
    labels{end + 1} = ['Highest SSIM: ' settingLabel(r, true)];
    comparison(views, labels, [2 3], [name ' - LPF family optima'], fullfile(folder, 'family_optima.png'));
    comparison(cellfun(@(x) detail(x, name), views, 'UniformOutput', false), ...
        labels, [2 3], [name ' - same detail crop'], fullfile(folder, 'family_optima_detail.png'));
    compareMatched(img, reference, 'low', name, folder);
    r = selected(end,:);
    exportPipeline(img, reference, 'low', r.Family{1}, r.D0, r.Order, fullfile(folder, 'selected'));
    fprintf('B %s: %d settings; %s D0=%g n=%g, PSNR %.3f, SSIM %.4f\n', ...
        name, height(results), r.Family{1}, r.D0, r.Order, r.PSNR, r.SSIM);
    checkpoint = allResults;
    if strcmp(mode, 'refine')
        checkpoint = [checkpoint; previous(~ismember(previous.File, allResults.File), :)];
    end
    writetable(checkpoint, fullfile(output, 'lpf_all_results.csv'));
    writetable(familyBest, fullfile(output, 'lpf_family_best.csv'));
    writetable(selected, fullfile(output, 'lpf_recommendations.csv'));
    writetable(bestSsim, fullfile(output, 'lpf_best_ssim.csv'));
end
if ~isempty(baseline)
    writetable(cell2table(baseline, 'VariableNames', {'File', 'PSNR', 'SSIM'}), ...
        fullfile(output, 'lpf_baseline.csv'));
end

hpfRows = cell(0, 6);
for k = 1:numel(index(2).input)
    path = index(2).input{k};
    [~, name, ext] = fileparts(path);
    img = imread(path);
    folder = fullfile(output, 'C', name);
    if ~isfolder(folder), mkdir(folder); end
    compareMatched(img, [], 'high', name, folder);
    shortSide = min(size(img, 1), size(img, 2));
    cutoffs = unique(max(1, round(shortSide * [.01 .02 .04 .06 .10 .16])));
    choices = configs([1 2 3 4 6], :); % Ideal, Gaussian, Butterworth n=1,2,4.
    for page = 1:ceil(numel(cutoffs)/3)
        views = {im2double(img)}; labels = {'Original input'};
        for c = 1:size(choices, 1)
            for cutoff = cutoffs((page-1)*3+1:min(page*3, numel(cutoffs)))
                family = choices{c, 1}; order = choices{c, 2};
                result = radialFilter(img, 'high', family, cutoff, order);
                display = min(max(result + .5, 0), 1);
                clipped = 100 * mean(result(:) < -.5 | result(:) > .5);
                hpfRows(end + 1, :) = {[name ext], family, cutoff, order, ...
                    sqrt(mean(result(:).^2)), clipped}; %#ok<AGROW>
                views{end + 1} = display; %#ok<AGROW>
                labels{end + 1} = filterLabel(family, cutoff, order); %#ok<AGROW>
                imwrite(display, fullfile(folder, sprintf('%s_n%d_D0_%g.png', family, order, cutoff)));
            end
        end
        comparison(views, labels, [4 4], [name ' - HPF +0.5, page ' num2str(page)], ...
            fullfile(folder, sprintf('candidates_%d.png', page)));
        comparison(cellfun(@(x) detail(x, name), views, 'UniformOutput', false), ...
            labels, [4 4], [name ' - same detail crop, page ' num2str(page)], ...
            fullfile(folder, sprintf('candidates_detail_%d.png', page)));
    end
    fprintf('C %s: %d settings exported.\n', name, numel(cutoffs) * size(choices, 1));
end
writetable(cell2table(hpfRows, 'VariableNames', ...
    {'File', 'Family', 'D0', 'Order', 'ResponseRMS', 'DisplayClippedPercent'}), ...
    fullfile(output, 'hpf_all_results.csv'));
fprintf('Results saved to %s\n', output);
runFrequencyExperiments('export-hpf');
end

function row = evaluate(img, ref, filename, family, cutoff, order, stage)
result = radialFilter(img, 'low', family, cutoff, order);
[p, s] = quality(result, ref);
row = {filename, family, cutoff, order, stage, p, s, ...
    100 * mean(result(:) < 0 | result(:) > 1)};
end

function [p, s] = quality(result, ref)
% Metrics use raw, unnormalized outputs, with a fixed intensity range of 1.
p = 10 * log10(1 / mean((result(:) - ref(:)).^2));
scores = zeros(1, size(ref, 3));
for c = 1:size(ref, 3)
    scores(c) = ssim(result(:,:,c), ref(:,:,c), 'DynamicRange', 1);
end
s = mean(scores);
end

function label = settingLabel(r, metrics)
label = filterLabel(r.Family{1}, r.D0, r.Order);
if metrics, label = sprintf('%s\nPSNR %.2f | SSIM %.4f', label, r.PSNR, r.SSIM); end
end

function label = filterLabel(family, cutoff, order)
label = sprintf('%s D0=%g', family, cutoff);
if strcmp(family, 'Butterworth'), label = sprintf('%s n=%g', label, order); end
end

function compareMatched(img, reference, pass, name, folder)
cutoffs = max(1, round(min(size(img, 1), size(img, 2)) * [.02 .06 .16]));
views = {im2double(img)}; labels = {'Input'};
if ~isempty(reference), views{end+1} = reference; labels{end+1} = 'Reference'; end
for family = {'Ideal', 'Gaussian', 'Butterworth'}
    for cutoff = cutoffs
        result = radialFilter(img, pass, family{1}, cutoff, 2);
        if strcmp(pass, 'high'), result = result + .5; end
        views{end+1} = min(max(result, 0), 1); %#ok<AGROW>
        labels{end+1} = sprintf('%s D0=%g', family{1}, cutoff); %#ok<AGROW>
        if strcmp(family{1}, 'Butterworth'), labels{end} = [labels{end} ' n=2']; end
    end
end
comparison(views, labels, [4 3], [name ' - matched cutoff comparison'], fullfile(folder, 'matched_cutoffs.png'));
end

function exportPipeline(img, reference, pass, family, cutoff, order, folder)
if ~isfolder(folder), mkdir(folder); end
[result, H, before, after] = radialFilter(img, pass, family, cutoff, order);
display = result;
if strcmp(pass, 'high'), display = display + .5; end
display = min(max(display, 0), 1);
scale = max(1, max(before(:)));
imwrite(display, fullfile(folder, 'result.png'));
imwrite(H, fullfile(folder, 'mask.png'));
imwrite(before / scale, fullfile(folder, 'spectrum_before.png'));
imwrite(after / scale, fullfile(folder, 'spectrum_after.png'));
save(fullfile(folder, 'raw.mat'), 'result', 'H', 'before', 'after', 'family', 'cutoff', 'order', 'pass');
views = {im2double(img), before / scale, H, after / scale, display};
labels = {'Input', 'Spectrum before (log)', 'Filter H(u,v)', 'Spectrum after (same scale)', 'Result'};
if strcmp(pass, 'high'), labels{5} = 'Result +0.5 (zero = middle gray)'; end
if ~isempty(reference), views{6} = reference; labels{6} = 'Reference'; end
comparison(views, labels, [2 3], sprintf('%s %s', upper(pass), filterLabel(family, cutoff, order)), ...
    fullfile(folder, 'pipeline.png'));
end

function crop = detail(img, name)
height = min(128, size(img, 1)); width = min(128, size(img, 2));
row = floor((size(img, 1)-height)/2)+1;
col = floor((size(img, 2)-width)/2)+1;
if contains(name, 'astronaut'), row = 65; col = 129; end
crop = img(row:row+height-1, col:col+width-1, :);
end

function comparison(views, labels, shape, heading, path)
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [50 50 1600 1100]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig, shape(1), shape(2), 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, heading, 'Interpreter', 'none', 'Color', 'black');
for k = 1:numel(views)
    ax = nexttile(layout);
    imshow(min(max(views{k}, 0), 1), 'Parent', ax);
    title(ax, labels{k}, 'Interpreter', 'none', 'FontSize', 11, 'Color', 'black');
end
exportgraphics(fig, path, 'Resolution', 120);
end
