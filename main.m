pkg load image;

global fig;
global images;
global current;

folder = 'planes/';
current = 1;
images = [];

files = dir(strcat(folder, '*.jpg'));

fig = figure("keypressfcn", @onKey);

for j = 1 : 1 %length(files)
  filename = strcat(folder, files(j).name);
  img = imread(filename);

  inf = imfinfo(filename);
  
  % color to grayscale
  if (!strcmp(inf.ColorType, 'grayscale'))
    img = rgb2gray(img);
  endif

  img = imresize(img, [159, 240]);
  
  % normalize
  img = uint8((double(img)-double(min(min(img))))*(255/double(max(max(img))- min(min(img)))));
  
  % gabor
  img = GaborEnergy(img, 4, 9, 9, 2, 0, 0);  
  
  images{j} = img;
  
endfor

imshow(images{1});

