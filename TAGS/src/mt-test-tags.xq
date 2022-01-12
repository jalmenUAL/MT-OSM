import module namespace mt = 'mt' at 'mt-osm-tags.xqm';

(: OPEN MAP ON BASEX INTERPRETER TO RUN TESTER :)



mt:TagsCOMPkvTest(.,"amenity",1,0,())


(:
mt:TagsCOMPkvkTest(.,"building",10,2,())
:)

(:
mt:TagsMISSkvkTest(.,"highway",20,10,()) 
:)

(:
 mt:TagsNameTest(.,"park",1,1)
:)