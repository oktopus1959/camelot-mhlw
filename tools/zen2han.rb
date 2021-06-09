#! /usr/bin/ruby
# -*- encoding: UTF-8 -*-
$KCODE = 'utf8' if RUBY_VERSION =~ /^1\.8/

hankaku_chars = '-0-9A-Za-z!"#$%&\'()[]{}|*+,./:;<=>?@^_`~\\'
zenkaku_chars = '‐０-９Ａ-Ｚａ-ｚ！”＃＄％＆’（）［］｛｝｜＊＋，．／：；＜＝＞？＠＾＿‘～￥'

while line = gets
  puts line.tr(zenkaku_chars, hankaku_chars)
end
