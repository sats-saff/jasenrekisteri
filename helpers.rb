require_relative 'reference_number.rb'


def viitenumero(pohja)
  ReferenceNumber.new(pohja, :grouping => true).to_s
end


