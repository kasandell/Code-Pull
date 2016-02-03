if !has('python')
	finish
endif

command! -nargs=1 Pull call PullCode(<f-args>)
function! PullCode(description)


python <<_EOF_

import json
import requests
import vim

class CodeRetriever:


	#initialize the class with keywords and language
	def __init__(self, initKeywords, language):
		self.keywords = initKeywords
		language_codes = {'javascript': 22,
			'swift':137,
			'python':19,
			'c': 28,
			'java':23,
			'php':24,
			'cpp':16,
			'lisp':29,
			'html':3,
			'header':15,
			'ruby':32,
			'perl':51,
			'vimscript':33,
			'haskell':40,
			'scala':47,
			'markdown':118,
			'pascal':46,
			'erlang':25,
			'actionscript':42,
			'lua':54,
			'go':55,
			'objective-c':21,
			'json':122,
			'd':45,
			'config':113,
			'ocaml':64,
			'coffeescript':106,
			'matlab':20,
			'assembly':34,
			'typescript':151}
		self.language = language_codes[language] #  this will be determined from the ending of the file
		#print self.language

	def removeCommentOnlyCode(self, codeGroups):

		def isComment(line):
			return line[0] in '#\'"' or line.startswith('//')

		def hasComments(group):
			return any([isComment(line) for line in group.splitlines()])

		return [g for g in codeGroups if not hasComments(g)]



	#get the groupings of lines that are returned
	def pickMostLikelyCode(self, lineSegments, code):
		#here we look for code that:
			#a) does shit(we don't want method declarations and all that shit, we want code)
			#b) seems to do the right thing (methods that are named similar to keywords)
			#TODO: implement an algorithm that finds other ways to predict if code does the right thing
			codeGroups = []
			codeLine =''

			#list of general programming terms we don't want included
			unwanted = ['string', 'int', 'double', 'float', 'bool', 'boolean', 'char', 'integer']
			#delete all general terms from the keywords
			self.keywords = [w for w in self.keywords if w.lower() not in unwanted]

			#compile the lines into code segments
			for outer in lineSegments:
				codeLine = '\n'.join([code[str(inner) for inner in outer])
				codeGroups.append(codeLine)
			codeGroups = self.removeCommentOnlyCode(codeGroups)
			highestKeywords = []
			kwdCount = 0
			#find the code segment that best matches our needs, based on keywords found in the code
			for segment in codeGroups:
				for word in self.keywords:
					kwdCount = kwdCount + segment.count(word)
				highestKeywords.append(kwdCount)
				kwdCount = 0
			wantedCode = highestKeywords.index(max(highestKeywords))
			return codeGroups[wantedCode]

	#scrape and grab code from github
	def querySearchCode(self):

		params = '+'.join(self.keywords)
		#params += self.language
		query = 'https://searchcode.com/api/codesearch_I/'#?q=reverse+string&lan=19'
		q = {'q':params,
			'lan':self.language}#for testing purposes, make this python. Will add a dict later that has language to number mappings
		param_str = '&'.join('%s=%s' %(k, v) for k,v in q.items())
		param_str = param_str.replace(' ', '+')

		#request the data from the page, and then we will pull the code out? or open the file to the location and pull out from start to end braces/ indent?
		page = requests.get(query, params = param_str)
		js = json.loads(page.content)
		firstCodeSet = js['results'][0]['lines']
		lineGroups = self.getLineGroups(firstCodeSet)
		#extract section of html containing top answer
		finCode = self.pickMostLikelyCode(lineGroups, firstCodeSet)
		return finCode
		#if we did, follow the link to the code, and extract the entire method that is there


	def getLineGroups(self, lineDict):
		numList = [int(k) for k,v in lineDict.items()]
		groupNumber = 0
		finGroups = []
		segment = []
		numList.sort()
		#until the list is empty
		while numList != []:
			#get the minimum line number
			init = min(numList)
			numList.remove(init)
			#if this is the first line ever, just put it in
			if segment == []:
				segment.append(init)
			else:
				#if the line is 1 greater than the max in the list, it is the next line, so append it
				if init == int(max(segment))+1:
					segment.append(init)
				#else, it belongs in a new group, so finalize the old group, and start a new one
				else:
					finGroups.append(segment)
					groupNumber = groupNumber + 1
					segment = []
					segment.append(init)
		finGroups.append(segment)
		return finGroups


args = vim.eval("a:description")

argsDict = args.split(' ')

vim.command("let r = &filetype")


ftype = vim.eval("r")


cr = CodeRetriever(argsDict, ftype)

fin = cr.querySearchCode()

codeArr = fin.splitlines()
vim.command("let ret = \"%s\"" %fin)

_EOF_


let codeArr = split(ret, "\n")
let codeArrReverse = reverse(codeArr)
for i in codeArrReverse
	call append('.', i)
endfor

endfunction
