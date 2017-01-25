
function result = GaborEnergy(img, filter_size, sigma_y, sigma_x, pr, x0, y0)

theta = [0, pi/4, pi/2, 3*pi/4];

filters = zeros(filter_size, filter_size, 4, 'double');
filter_sum = 0;

for i = 1 : 4
    [even, ~] = GaborD(filter_size, sigma_y, sigma_x, theta(i), pr, x0, y0);
    filters(:,:,i) = even;
    filter_sum = filter_sum + even; 
end

images = zeros(filter_size, filter_size, 4, 'double');
for i = 1 : 4
    images(:,:,i) = conv2(double(img), (filters(:,:,i)./filter_sum), 'same');
end


conv_image_rr_filter ,'same');
conv_image_l = conv2(double(img), l_filter ,'same');

result = abs(conv_image_r - conv_image_l);

end