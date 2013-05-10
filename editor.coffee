defaultParseOptions =
  loc: true #loc: {start: {line: (1-based), column: (0-based)}, end:}
  range: false #range: [startIndex, endIndex]
  tokens: true # return addional array of all tokens found
  tolerant: false # tolerate errors, include errors: []; doesn't seem to work yet
  comments: false # comments: [type: value:]

class @ReactiveAce
  constructor: (parseOptions = {}) ->
    self = this
    @_deps = {}
    @_parseOptions = _.extend defaultParseOptions, parseOptions

    #Populate the parsed body and parse error
    Meteor.autorun ->
      self._parseBody()

    #Calculate checksum
    #Meteor.autorun ->
      #self._calculateChecksum()

  _parseBody: ->
    return unless @parseEnabled
    try
      @_parsedBody = esprima.parse editor.value, @_parseOptions
      @changed 'parsedBody'
      if @_parseError
        @_parseError = null
        @changed 'parseError'
    catch e
      @_parseError = e
      @changed 'parseError'

  _calculateChecksum: ->
    return unless @value?
    checksum = crc32 @value
    return if checksum == @_checksum
    @_checksum = checksum
    @changed 'checksum'

  attach: (editorId) ->
    #return if @_attached
    #@_attached = true
    @_editor = ace.edit editorId
    for k, dep of @deps
      dep.changed()
    @setupEvents()

  depend: (key) ->
    @_deps[key] ?= new Deps.Dependency
    @_deps[key].depend()

  changed: (key) ->
    @_deps[key]?.changed()

  setupEvents: ->
    @_editor.on "changeSelection", =>
      #TODO could be smarter and only invalidate these when they change
      @changed 'lineNumber'
      @changed 'column'
      @changed 'selection'

    @_editor.on "change", =>
      @changed 'value'

    #Changing syntax mode somethings has a delay, which means reactivity is
    #triggered prematurely.
    @_editor.getSession().on 'changeMode', =>
      @changed 'syntaxMode'

  _getEditor: ->
    @depend 'attached'
    return @_editor

  _getSession: ->
    @depend 'attached'
    return @_editor?.getSession()

ReactiveAce.addProperty = (name, getter, setter) ->
  descriptor = {}
  if getter
    descriptor.get = ->
      @depend name
      return getter.call(this)
  if setter
    descriptor.set = (value) ->
      return if getter and value == getter.call this
      setter.call this, value
      @changed name
  Object.defineProperty ReactiveAce.prototype, name, descriptor

#1-indexed
ReactiveAce.addProperty 'lineNumber', ->
    row = @_editor?.getCursorPosition().row
    return null unless row?
    return row + 1
  , (value) ->
    row = value - 1
    column = @_editor?.getCursorPosition().column
    @_editor?.navigateTo row, column

#0-indexed
ReactiveAce.addProperty 'column', ->
    column = @_editor?.getCursorPosition().column
    return null unless column?
    return column
  , (value) ->
    row = @_editor?.getCursorPosition().row
    @_editor?.navigateTo row, value

ReactiveAce.addProperty 'showInvisibles', ->
    @_editor?.getShowInvisibles()
  , (value) ->
    @_editor?.setShowInvisibles value

ReactiveAce.addProperty 'tabSize', ->
    return @_getSession()?.getTabSize()
  , (value) ->
    @_getSession()?.setTabSize value

ReactiveAce.addProperty "theme", ->
    return @_editor?.getTheme()?.split("/").pop()
  , (value) ->
    @_editor?.setTheme "ace/theme/#{value}"

ReactiveAce.addProperty "syntaxMode", ->
    @_getSession()?.getMode().$id?.split('/').pop()
  , (value) ->
    if value
      @_getSession()?.setMode "ace/mode/#{value}"
    else
      @_getSession()?.setMode null

#TODO: Doesn't work yet
#ReactiveAce.addProperty "keybinding", ->
    #return @_editor?.getKeyboardHandler()
  #, (value) ->
    #@_editor?.setKeyboardHandler "ace/keyboard/#{value}"

ReactiveAce.addProperty 'useSoftTabs', ->
    return @_getSession()?.getUseSoftTabs()
  , (value) ->
    @_getSession()?.setUseSoftTabs value
    
ReactiveAce.addProperty 'wordWrap', ->
    return @_getSession()?.getUseWrapMode()
  , (value) ->
    @_getSession()?.setUseWrapMode value
    @_getSession()?.setWrapLimitRange null, null

ReactiveAce.addProperty 'parseEnabled', ->
    @_parseEnabled
  , (value) ->
    @_parseEnabled = value

ReactiveAce.addProperty 'newLineMode', ->
    return @_getSession()?.getDocument().getNewLineMode()
  , (value) ->
    @_getSession()?.getDocument().setNewLineMode(value)


###
# Read Only properties
###

ReactiveAce.addProperty 'parsedBody', ->
  @_parsedBody

#Error {index: 1, lineNumber: 1, column: 2, description: "Unexpected end of input"}
ReactiveAce.addProperty 'parseError', ->
  @_parseError


#TODO: Throttle this with _.throttle
ReactiveAce.addProperty 'value', ->
    return @_editor?.getValue()

ReactiveAce.addProperty 'selection', ->
    range = @_editor?.getSelectionRange()
    return unless range
    range.start.lineNumber = range.start.row + 1
    range.end.lineNumber = range.end.row + 1
    return range
    #TODO code below doesn't work..
#  , (value) ->
#    @_editor?.clearSelection()
#    @_editor?.addSelectionMarker(value)

ReactiveAce.addProperty 'checksum', ->
  #Do it the safe but inefficient way for now.
  return unless @value?
  checksum = crc32 @value
  #@_checksum
