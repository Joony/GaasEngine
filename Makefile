build:
	/Developer/zActionscript/flex_sdk_4/bin/mxmlc src/Test.as -o="Test.swf" -debug=true -sp="src/" -default-size 320 240 -target-player=10
test:
	/Developer/zActionscript/flex_sdk_4/bin/fdb Test.swf