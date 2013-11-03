# encoding: utf-8

Given /^: マウントポイントに移動する$/ do
  cd "mnt"
  current_dir.should == @features_root + "/mnt"
end

When /^: 以下の内容のファイルを作成する$/ do |table|
  file = table.hashes[0]
  write_file(file[:filename], file[:content])
end

When /^: "(.*?)" に "(.*?)" を追記する$/ do |arg1, arg2|
  append_to_file(arg1, arg2)
end

When /^: "(.*?)" を "(.*?)" にコピーする$/ do |arg1, arg2|
  run("cp #{arg1} #{arg2}")
end

When /^: "(.*?)" の名前をを "(.*?)" に変更する$/ do |arg1, arg2|
  run("mv #{arg1} #{arg2}")
end

When /^: ファイル "(.*?)" を削除する$/ do |arg1|
  remove_file(arg1)
end

Then /^: ディレクトリに "(.*?)" が存在(する|しない)$/ do |arg1, arg2|
  check_file_presence([arg1], arg2 == "する")
end

Then /^: "(.*?)" の内容に "(.*?)" が含まれている$/ do |arg1, arg2|
  check_file_content(arg1, arg2, true)
end
