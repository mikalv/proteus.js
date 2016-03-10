# Wire
# Copyright (C) 2016 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

CBOR = require 'cbor-codec'

DontCallConstructor = require '../errors/DontCallConstructor'
ClassUtil = require '../util/ClassUtil'
TypeUtil = require '../util/TypeUtil'

MacKey = require '../derived/MacKey'
DerivedSecrets = require '../derived/DerivedSecrets'

MessageKeys = require './MessageKeys'

module.exports = class ChainKey
  constructor: ->
    throw new DontCallConstructor @

  ###
  @param key [Proteus.derived.MacKey] Mac Key generated by derived secrets
  ###
  @from_mac_key: (key, counter) ->
    TypeUtil.assert_is_instance MacKey, key
    TypeUtil.assert_is_integer counter

    ck = ClassUtil.new_instance ChainKey
    ck.key = key
    ck.idx = counter
    return ck

  next: ->
    ck = ClassUtil.new_instance ChainKey
    ck.key = MacKey.new @key.sign('1')
    ck.idx = @idx + 1
    return ck

  message_keys: ->
    base = @key.sign '0'
    dsecs = DerivedSecrets.kdf_without_salt base, 'hash_ratchet'

    return MessageKeys.new dsecs.cipher_key, dsecs.mac_key, @idx

  encode: (e) ->
    e.object 2
    e.u8 0; @key.encode e
    e.u8 1; e.u32 @idx

  @decode: (d) ->
    TypeUtil.assert_is_instance CBOR.Decoder, d

    self = ClassUtil.new_instance ChainKey

    nprops = d.object()
    for [0..(nprops - 1)]
      switch d.u8()
        when 0 then self.key = MacKey.decode d
        when 1 then self.idx = d.u32()
        else d.skip()

    TypeUtil.assert_is_instance MacKey, self.key
    TypeUtil.assert_is_integer self.idx

    return self
