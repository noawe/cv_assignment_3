addpath "./vlfeat-0.9.20/toolbox";
addpath "./libsvm-3.22/matlab/";
pkg load image;
vl_setup;

global fig;
global images;
global current;

folder = 'img/mini_airplanes/';
current = 1;
images = [];
trainset_size = 100;
bow_size = 100; % size of bow dictionary

%build datasets with labels and filenames
plane_set = struct("label", 1, "file", glob(strcat('img/planes/', '*.jpg')));
car_set = struct("label", -1, "file", glob(strcat('img/cars/', '*.jpg')));

%split into training and test images
train_set = vertcat(plane_set(1:trainset_size), car_set(1:trainset_size));
test_set = vertcat(plane_set((trainset_size+1):length(plane_set)), car_set((trainset_size+1):length(car_set)));

function img = prepare_image (filename)
	img = imread(filename);

	inf = imfinfo(filename);

	% color to grayscale
	if (!strcmp(inf.ColorType, 'grayscale'))
	img = rgb2gray(img);
	endif

	img = imresize(img, [159, 240]);

	% normalize
	img = uint8((double(img)-double(min(min(img))))*(255/double(max(max(img))- min(min(img)))));

endfunction

function features = get_features(img)
	% gabor 
	% TODO: find working parameters...
	%  img = GaborEnergy(img, 4, 9, 9, 2, 0, 0);  

	% sift
	[f,features] = vl_sift(single(img));

endfunction

function [bow, model] = train (train_set, bow_size)

	features = [];
	num_features = [];
	train_labels = [];

	for j = 1 : length(train_set)
	  img = prepare_image (train_set(j).file);

	  % feature extraction
	  img_features = get_features(img);
	  features = horzcat(features, img_features); % add feature descriptors
	  num_features = [num_features ; size(img_features, 2)]; % save number of features per image
	  train_labels =  [train_labels; train_set(j).label];
	endfor

	%vector quantization

	% clustering
	[bow, assignments] = vl_kmeans(single(features), bow_size, 'Initialization', 'plusplus');

	% histogram computation
	train_instances = [];
	index = [ 0 ; cumsum(num_features) ]; %build index vector

	% build histogram from cluster assignments
	for i = 1 : length(num_features)
		train_instances  = [train_instances ; histc(assignments(: , (index(i)+1):index(i+1) ), 1:bow_size)];
	endfor

	model = svmtrain(double(train_labels), double(train_instances), '-s 0 -t 0 -c 1');

endfunction

function test_instance = get_test_instance (filename, bow)

	img = prepare_image (filename);
	img_features = get_features(img);
	assignments = [];
	bow_size = size(bow, 2);
	for i = 1 : size(img_features, 2)
	 [~, k] = min(vl_alldist(single(img_features(:,i)), bow));
	 assignments = [assignments; k];
	endfor
	test_instance = histc(assignments, 1:bow_size);

endfunction

function test (test_set, bow, model)

	for i = 1:length(test_set)
		t = get_test_instance (test_set(i).file, bow);
		svmpredict(test_set(i).label, double(rot90(t)), model)
	endfor

endfunction


%training
[bow, model] = train (train_set, bow_size);

%testing
test (test_set, bow, model);


