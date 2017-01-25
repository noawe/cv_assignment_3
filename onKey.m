function onKey(hobj, evt)
  global fig;
  global images;
  global current;

  if (strcmp(evt.Key, "escape") || current >= length(images))
    close(fig);
  elseif (strcmp(evt.Key, "any") || strcmp(evt.Key, "right"))
    current = current + 1;
    imshow(images{current});
  elseif (strcmp(evt.Key, "left") && current > 1)
    current = current - 1;
    imshow(images{current});
  end
end