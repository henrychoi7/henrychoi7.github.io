---
layout: post
title: GitHub Mastering Markdown
---

### [GitHub] 마크다운 실습하기

오늘은 GitHub의 Mastering Markdown을 실습해 보았다.

It's very easy to make some words **bold** and other words *italic* with Markdown. You can even [link to Google!](http://google.com)


Sometimes you want numbered lists:

1. One
2. Two
3. Three

Sometimes you want bullet points:

* Start a line with a star
* Profit!

Alternatively,

- Dashes work just as well
- And if you have sub points, put two spaces before the dash or star:
  - Like this
  - And this


If you want to embed images, this is how you do it:

![Image of Yaktocat](https://octodex.github.com/images/yaktocat.png)


# Structured documents

Sometimes it's useful to have different levels of headings to structure your documents. Start lines with a '#' to create headings. Multiple '##' in a row denote smaller heading sizes.

### This is a third-tier heading

You can use one '#' all the way up to '######' six for different heading sizes.

If you'd like to quote someone, use the > character before the line:

> Coffee. The finest organic suspension ever devised... I beast the Borg with it.
> - Captain Janeway


There are many different ways to style code with GitHub's markdown. If you have inline code blocks, wrap them in backticks:
`var example = true`. If you've got a longer block of code, you can indent with four spaces:

    if (isAwesome){
      return true
    }

GitHub also supports something called code fencing, which allows for multiple lines without indentation:

```
if (isAwesome){
  return true
}
```

And if you'd like to use syntax highlighting, include the language:

```javascript
if (isAwesome){
  return true
}
```


GitHub supports many extras in Markdown that helps you reference and link to people. If you ever want to direct a comment at someone, you can prefix their name with an @ symbol: Hey @kneath - love your sweater!

But I have to admit, tasks lists are my favorite:

- [x] This is a complete item
- [ ] This is an incomplete item

When you include a task list in the first comment of an Issue, you will see a helpful progress bar in your list of issues. It works in Pull Requests, too!

And, of course emoji! :sparkles: :camel: :boom:


# Syntax Guide

Here's an overview of Markdown syntax that you can use anywhere on GitHub.com or in your own text files.

## Headers


# This is an <h1> tag
## This is an <h2> tag
###### This is an <h6> tag


## Emphasis


*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

_You **can** combine them_


## Lists

### Unordered


* Item 1
* Item 2
  * Item 2a
  * Item 2b


### Ordered


1. Item 1
1. Item 2
1. Item 3
  1. Item 3a
  1. Item 3b

## Links

http://github.com - automatic!
[GitHub](http://github.com)

## Blockquotes

As Kanye West said:

> We're living the future so
> the present is our past.

## Inline code

I think you should use an `<addr>` element here instead.

## Syntax highlighting

Here's an example of how you can use syntax highlighting with GitHub Flavored Markdown:

```javascript
function fancyAlert(arg) {
  if(arg) {
    $.facebox({div:'#foo'})
  }
}
```

You can also simply indent your code by four spaces:

    function fancyAlert(arg) {
      if(arg) {
        $.facebox({div:'#foo'})
      }
    }

Here's an example of Python code without syntax highlighting:

def foo():
  if not bar:
    return true

## Task Lists

- [x] @mentions, #refs, [links](), **formatting**, and <del>tags</del> supported
- [x] list syntax required (any unordered or ordered list supported)
- [x] this is a complete item
- [ ] this is an incomplete item

if you include a task list in the first comment of an Issue, you will get a handy progress indicator in your issue list. It also works in Pull Requests!

## Tables

You can create tables by assembling a list of words and dividing them with hyphens `-` (for the first row), and then separating each column with a pipe `|`:

First Header | Second Header
------------ | -------------
Content from cell 1 | Content from cell 2
Content in the first column | Content int the second column

## SHA references

Any reference to a commit's SHA-1 hash will be automatically converted into a link to that commit on GitHub.

16c999e8c71134401a78d4d46435517b2271d6ac
mojombo@16c999e8c71134401a78d4d46435517b2271d6ac
mojombo/github-flavored-markdown@16c999e8c71134401a78d4d46435517b2271d6ac

## Issue references within a repository

Any number that refers to an Issue or Pull Request will be automatically converted into a link.

#1
mojombo#1
mojombo/github-flavored-markdown#1

## Username @mentions

Typing an `@` symbol, followed by a username, will notify that person to come and view the comment. This is called an "@mention", because you're mentioning the individual. You can also @mention teams within an organization.

## Automatic linking for URLs

Any URL (like `http://www.github.com/`) will be automatically converted into a clickable link.

## Strikethrough

Any word wrapped with two tildes (like `~~this~~`) will appear crossed out.

## Emoji

GitHub supports emoji!
