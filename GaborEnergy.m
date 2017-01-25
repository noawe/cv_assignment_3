% not sure if what happens here is correct for our goal..
function result = GaborEnergy(img, filter_size, sigma_y, sigma_x, pr, x0, y0)

theta = [0, pi/4, pi/2, 3*pi/4];

filters = zeros(filter_size, filter_size, 4, 'double');
filter_sum = 0;

for i = 1 : 4
    [even, ~] = GaborD(filter_size, sigma_y, sigma_x, theta(i), pr, x0, y0);
    filters(:,:,i) = even;
    filter_sum = filter_sum + even; 
end

for i = 1 : 4
    filters(:,:,i) = (filters(:,:,i)./filter_sum);
end

r_filter = (filters(:,:,2));
l_filter = (filters(:,:,4));

conv_image_r = conv2(double(img), r_filter ,'same');
conv_image_l = conv2(double(img), l_filter ,'same');

result = abs(conv_image_r - conv_image_l);

end