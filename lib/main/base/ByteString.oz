ByteString =
byteString(
   is           : Boot_ByteString.is
   make         : fun {$ Vs}
                     {Boot_VirtualString.toByteString
                      Vs 0 Vs}
                  end
   get          : Boot_ByteString.get
   append       : Boot_ByteString.append
   slice        : Boot_ByteString.slice
   width        : Boot_ByteString.width
   length       : Boot_ByteString.width
   toString     : Boot_ByteString.toString
   toStringWithTail: Boot_ByteString.toStringWithTail
   strchr       : Boot_ByteString.strchr
   )
