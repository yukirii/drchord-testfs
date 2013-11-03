# encoding: utf-8

Given /^: マウントポイントに移動する$/ do
  cd "mnt"
  current_dir.should == @features_root + "/mnt"
end

When /^: 以下の内容のファイルを作成する$/ do |table|
  file = table.hashes[0]
  write_file(file[:filename], file[:content])
end

Then /^: ディレクトリに "(.*?)" が存在する$/ do |arg1|
  check_file_presence([arg1], true)
end

Then /^: "(.*?)" の内容に "(.*?)" が含まれている$/ do |arg1, arg2|
  check_file_content(arg1, arg2, true)
end
