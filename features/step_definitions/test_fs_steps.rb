# encoding: utf-8

Given /^: マウントポイントに移動する$/ do
  cd "mnt"
  current_dir.should == @features_root + "/mnt"
end

Given /^: "(.*?)" ディレクトリに移動する$/ do |arg1|
  cd arg1
  current_dir.should == @features_root + "/mnt" + "/#{arg1}"
end

Given /^: "(.*?)" ディレクトリに (\d+) 個のテストデータを作成する$/ do |arg1, arg2|
  arg2.to_i.times do |i|
    write_file("#{arg1}/#{i}.txt", "#{i.to_s*10}")
  end
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

When /^: "(.*?)" ディレクトリを "(.*?)" にコピーする$/ do |arg1, arg2|
  run("cp -r #{arg1} #{arg2}")
end

When /^: "(.*?)" の名前を "(.*?)" に変更する$/ do |arg1, arg2|
  run("mv #{arg1} #{arg2}")
end

When /^: ファイル "(.*?)" を削除する$/ do |arg1|
  remove_file(arg1)
end

When /^: ディレクトリ "(.*?)" を作成する$/ do |arg1|
  create_dir(arg1)
end

When /^: "(.*?)" ディレクトリを "(.*?)" に(移動|リネーム)する$/ do |arg1, arg2, arg3|
  run("mv #{arg1} #{arg2}")
end

When /^: "(.*?)" ディレクトリを削除する$/ do |arg1|
  remove_dir(arg1)
end

Then /^: ディレクトリに "(.*?)" (ファイル|ディレクトリ)が存在(する|しない)$/ do |arg1, arg2, arg3|
  if arg2 == "ファイル"
    check_file_presence([arg1], arg3 == "する")
  elsif arg2 == "ディレクトリ"
    check_directory_presence([arg1], arg3 == "する")
  end
end

Then /^: "(.*?)" の内容に "(.*?)" が含まれている$/ do |arg1, arg2|
  check_file_content(arg1, arg2, true)
end

Then /^: "(.*?)" ディレクトリに移動できる$/ do |arg1|
  cd arg1
  current_dir.should == @features_root + "/mnt" + "/#{arg1}"
end

Then /^: (\d+) 個のテストデータが存在する$/ do |arg1|
  arg1.to_i.times do |i|
    check_file_presence(["#{i}.txt"], true)
    check_file_content("#{i}.txt", "#{i.to_s*10}", true)
  end
end


