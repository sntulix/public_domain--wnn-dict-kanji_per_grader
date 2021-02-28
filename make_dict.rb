#!/usr/bin/ruby
# coding: utf-8

class Base_Word
	attr_accessor :yomi, :character, :category, :grader
	def initialize
		@yomi = ""
		@character = ""
		@category = ""
		@grader = ""
	end

	def to_word_define
		return @yomi + "	" + @character + "	" + @category + "	" + @grader
	end

	def length_utf8
		length = 0
		@character.each_char { |c| charcode=c.unpack("H*")[0].hex; if (0xe2ba80 <= charcode && charcode <= 0xe9bea0) || (0xefa480 <= charcode && charcode <= 0xefa9ad) || (0xefbc80 <= charcode && charcode <= 0xefbda0)  || (0xefbfa0 <= charcode && charcode <= 0xefbfa6) then length+=2 else length+=1 end }
		return length
	end
end

class Base_Dict
	attr_accessor :word_list
	@@base_dict_file = "assets/kihon.u"
	def initialize
		@word_list = []
		base_dict = File.open(@@base_dict_file, mode="rb:euc-jp:utf-8")
		until base_dict.eof?
			line = base_dict.gets()
			word_define = line.split(" ")[0...3]
			word_object = Base_Word.new
			word_object.yomi = word_define[0]
			word_object.character = word_define[1]
			word_object.category = word_define[2]
			word_object.grader = ''
			@word_list.push(word_object)
		end
	end

	def get_list
		return @word_list
	end

	def show
		for word_object in get_list
			if word_object.character.length == 1
				print word_object.yomi + " "
				print word_object.character + "\n"
			end
		end
	end
end	

class Gakunen_Kanji_Table
	@@gakunen_roman_list = {"ichi"=>"小学第一学年", "ni"=>"小学第二学年", "san"=>"小学第三学年", "yon"=>"小学第四学年", "go"=>"小学第五学年", "roku"=>"小学第六学年"}
	def get_gakunen_list
		return @@gakunen_roman_list.keys
	end

	def get_list(gakunen_roman_key)
		if @@gakunen_roman_list.include?(gakunen_roman_key)
			gakunen_kanji_text = File.open("data/dai-"+gakunen_roman_key+"-gakunen.txt", mode="rb:utf-8")
			kanji_list = gakunen_kanji_text.gets().chomp().split("　")
			return kanji_list
		end
	end

	def get_gakunen_name(gakunen_key)
		return @@gakunen_roman_list[gakunen_key]
	end
end	

base_dict = Base_Dict.new
word_list = base_dict.get_list
gakunen_kanji_table = Gakunen_Kanji_Table.new
gakunen_list = gakunen_kanji_table.get_gakunen_list
for current_grader in gakunen_list
	kanji_list = gakunen_kanji_table.get_list(current_grader)
	current_grader_name = gakunen_kanji_table.get_gakunen_name(current_grader)
	print current_grader_name + "の漢字と辞書を照合..."
	for kanji in kanji_list
		print kanji + "と"
		for word in word_list
			print word.character
			word.character.each_char{ |c| if kanji==c then word.grader=current_grader_name end }
			backspace_buf = ""
			word.length_utf8.times { backspace_buf += "\b \b" }
			print backspace_buf
			STDOUT.flush
		end
		print "\b\b\b\b"
		STDOUT.flush
	end
	print "完了しました。"
	print "\n"
end

for word in word_list
	print word.to_word_define + "\n"
end
