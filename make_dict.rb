#!/usr/bin/ruby
# coding: utf-8

class Base_Character
	attr_accessor :char, :grader
	def initialize(character)
		@char = character
		@grader = ""
	end

	def get_width_on_term
		charcode = @char.unpack("H*")[0].hex
		if (0xe2ba80 <= charcode && charcode <= 0xe9bea0) || (0xefa480 <= charcode && charcode <= 0xefa9ad) || (0xefbc80 <= charcode && charcode <= 0xefbda0)  || (0xefbfa0 <= charcode && charcode <= 0xefbfa6)
			return 2 
		else
			return 1
		end
	end
end

class Base_Word
	attr_accessor :yomi, :characters, :category, :grader
	def initialize
		@yomi = ""
		@characters = []
		@category = ""
		@grader = ""
	end

	def get_characters
		word = ""
		@characters.each { |c| word += c.char }
		return word
	end
		
	def to_word_define
		word = ""
		for char in @characters
			word += char.char
		end
		return @yomi + "	" + word + "	" + @category + "	" + @grader
	end

	def length_by_width # total width of characters on terminal
		length = 0
		@characters.each { |c| length += c.get_width_on_term }
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
			word_define[1].each_char { |c| word_object.characters.push(Base_Character.new(c)) }
			word_object.category = word_define[2]
			word_object.grader = ''
			@word_list.push(word_object)
		end
		base_dict.close
	end

	def get_list
		return @word_list
	end

	def show
		for word_object in get_list
			if word_object.character.length == 1
				STDERR.print word_object.yomi + " "
				STDERR.print word_object.character + "\n"
			end
		end
	end
end	

class Dict_Writer
	def write_msime(word_list)
		write_handle = File.open("dict-msime.txt", mode="wb:utf-16le")
		write_handle.write "\uFEFF"  # BOMを出力
		for word in word_list
			write_handle.write(word.to_word_define+"\r\n")
		end
		write_handle.close
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
			gakunen_kanji_text.close
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
	STDERR.print current_grader_name + "の漢字と辞書を照合..."
	for kanji in kanji_list
		STDERR.print kanji + "と"
		for word in word_list
			STDERR.print word.get_characters
			word.characters.each { |c| if kanji==c then word.grader="#"+current_grader_name end }
			backspace_buf = ""
			word.length_by_width.times { backspace_buf += "\b \b" }
			STDERR.print backspace_buf
			STDERR.flush
		end
		STDERR.print "\b\b\b\b"
		STDERR.flush
	end
	STDERR.print "完了しました。"
	STDERR.print "\n"
end

dict_writer = Dict_Writer.new
dict_writer.write_msime(word_list)
