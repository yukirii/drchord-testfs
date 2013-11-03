# encoding: utf-8

Given /^: マウントポイントに移動する$/ do
  cd "mnt"
  current_dir.should == @features_root + "/mnt"
end

When /^: コマンド "(.*?)" を実行する$/ do |arg1|
  #run(arg1)
  write_file("hoge.txt", "hogehoge")
end

Then /^: ディレクトリに "(.*?)" が存在する$/ do |arg1|
  check_file_presence([arg1], true)
end

Then /^: "(.*?)" の内容に "(.*?)" が含まれている$/ do |arg1, arg2|
  check_file_content(arg1, arg2, true)
end
