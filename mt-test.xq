import module namespace mt = 'mt' at 'mt-osm.xqm';

(: OPEN MAP ON BASEX INTERPRETER TO RUN TESTER :)





(:
mt:TagsCOMPkvTest(.,"building",1,1,())
:)

(:
mt:TagsCOMPkkTest(.,"amenity",2,())
:)

(:mt:TagsNameTest(.,"hotel",1,0):)

(:
mt:NoDeadlockTest(.,"Calle Calzada de Castro",())
:)

(:
mt:NoIsolatedWayTest(.,"Calle Calzada de Castro",())
:)

(:
mt:ExitWayTest(.,"Calle Calzada de Castro",())
:)

(:
mt:EntranceWayTest(.,"Calle Calzada de Castro",())
:)

(:
mt:ExitRAboutTest(.,"Calle Calzada de Castro",())
:)

(:
mt:EntRAboutTest(.,"Calle Calzada de Castro",())
:)

(:
mt:ConnectedTest(.,"Calle Calzada de Castro",())
:)

(:
mt:AreaNoIntTest(.,"Calle de Alerce",())
:)

(:
mt:NoOverlapTest(.,"Estación de Almería",())
:)
