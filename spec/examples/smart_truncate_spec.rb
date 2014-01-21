require_relative '../../examples/smart_truncate'

describe 'smart_truncate' do
	it 'truncates at the nearest word boundary, and doesnt include the ellipsis length in the count' do
		result = smart_truncate("A very nice show happening in Jan", 30)
		result.should == "A very nice show happening in ..."
		result.length.should == 33
	end
end