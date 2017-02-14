addpath "./vlfeat-0.9.20/toolbox";
addpath "./libsvm-3.22/matlab/";
pkg load image;
vl_setup;

global fig;
global images;
global current;

current = 1;
images = [];
trainset_size = 75;
bow_size = 100; % size of bow dictionary

% type
% 1 = plane
% -1 = car

%build datasets with types and filenames
plane_set = struct("type", 1, "file", glob(strcat('img/planes/', '*.jpg')));
car_set = struct("type", -1, "file", glob(strcat('img/cars/', '*.jpg')));

plane_set = plane_set(randperm(length(plane_set)));
car_set = car_set(randperm(length(car_set)));

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
	% TODO: f working parameters...
	%  img = GaborEnergy(img, 4, 9, 9, 2, 0, 0);  

	% sift
	[f,features] = vl_sift(single(img));

endfunction

function [bow, model] = train (train_set, bow_size)

	features = [];
	num_features = [];
	train_types = [];

	for j = 1 : length(train_set)
	  img = prepare_image (train_set(j).file);

	  % feature extraction
	  img_features = get_features(img);
	  features = horzcat(features, img_features); % add feature descriptors
	  num_features = [num_features ; size(img_features, 2)]; % save number of features per image
	  train_types =  [train_types; train_set(j).type];
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

	model = svmtrain(double(train_types), double(train_instances), '-s 0 -t 0 -c 1');

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

function type = get_type(n)
  if (n == 1)
    type = 'plane';
  elseif
    type = 'car';
  endif
endfunction

function test (test_set, bow, model)
  
  % Positive = Plane
  TP = 0; TN = 0; FP = 0; FN = 0;

	for i = 1:length(test_set)
		t = get_test_instance (test_set(i).file, bow);
		[predicted_type] = svmpredict(test_set(i).type, double(rot90(t)), model, '-q');
    
    % print results & count
    result_string = 'Test Result: ';
    if (test_set(i).type == predicted_type)
      result_string = [result_string, 'correct ('];
      if (predicted_type == 1) TP++; elseif TN++; endif;
    elseif
      result_string = [result_string, 'FAILED ('];
      if (predicted_type == 1) FP++; elseif FN++; endif;
    endif
    result_string = [result_string, get_type(predicted_type), ')'];
    disp(result_string);
  endfor
  
  disp('#############################');
  disp(['Tested ', num2str(i) , ' pictures']);
  disp(['TP: ', num2str(TP), ' TN: ', num2str(TN), ' FP: ', num2str(FP), ' FN: ', num2str(FN)]);
  success_rate = (TP + TN) / i;
  disp(['success rate: ', num2str(success_rate)]);

endfunction

%training
[bow, model] = train (train_set, bow_size);

%testing
test (test_set, bow, model);
