if !has('python')
	finish
endif

command! -nargs=1 Pull call PullCode(<f-args>)
function! PullCode(description)


python <<_EOF_

#import csv
import os
import collections
from HTMLParser import HTMLParser
import re
import urllib
import urllib2
import requests
import vim
class CodeRetriever:

	#initialize the class empty
	#this will probably never get used, but if I end up using this somewhere else, it could work out well
	def __init__(self):
		self.keywords = []
		self.language = 19#default to the language we are writing in



	#initialize the class with keywords and language
	def __init__(self, initKeywords, lang):
		self.keywords = initKeywords
		d = {'javascript': '22',
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
		l = d[lang]
		self.language = int(l)#this will be determined from the ending of the file
		#print self.language

	def removeCommentOnlyCode(self, codeGroups):
		allComment = []
		for group in codeGroups:
			lines = group.split('\n')
			for line in lines:
				if line.startswith('#') or line.startswith('//')or line.startswith('\'') or line.startswith('"'):
					allComment.append(True)
				else:
					allComment.append(False)
			if False not in allComment:
				codeGroups.remove(group)
		return codeGroups



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
			for word in unwanted:
				for check in self.keywords:
					if word.lower() == check.lower():
						self.keywords.remove(check)

			#compile the lines into code segments
			for outer in lineSegments:
				for inner in outer:
					codeLine = codeLine + code[str(inner)] + '\n'
				codeGroups.append(codeLine)
				codeLine = ''
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

		params = ''
		for i in self.keywords:
			#print i
			params = params + i + '+'
			#print i
		params = params[:-1]#remove the ending '+'
		#params += self.language
		query = 'https://searchcode.com/api/codesearch_I/'#?q=reverse+string&lan=19'
		q = {'q':params,
			'lan':self.language}#for testing purposes, make this python. Will add a dict later that has language to number mappings
		#request the data from the page, and then we will pull the code out? or open the file to the location and pull out from start to end braces/ indent?
		page = requests.get(query, params=q)
		js = page.json()
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

codeArr = fin.split('\n')
vim.command("let ret = \"%s\"" %fin)

_EOF_


let codeArr = split(ret, "\n")
let codeArrReverse = reverse(codeArr)
for i in codeArrReverse
	call append('.', i)
endfor

endfunction
