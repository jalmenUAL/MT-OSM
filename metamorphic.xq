declare variable $map := .;

(: M :)

declare function local:M($type,$cond)
{
  filter($map/osm/*,function($e){local:type($e,$type) and $cond($e)})
};

(: Node :)

declare function local:Node($nd)
{
  let $ref := data($nd/@ref)
  return $map/osm/node[@id=$ref]
};

(: Lat :)

declare function local:Lat($nd)
{
  data($nd/@lat)
};

(: Lon :)

declare function local:Lon($nd)
{
  data($nd/@lon)
};

(: type :)

declare function local:type($e,$type)
{
  if ($type="*") then name($e)="node" or name($e)="way"
  else if ($type="node") then name($e)="node"
  else name($e)="way"
};

(: TagsCOMPkv :)
 
declare function local:TagsCOMPkv($O1,$O2,$epsilon,$delta)
{
   if (count($O1 intersect $O2) <= $epsilon)
   then
   count
   (for $e2 in $O2
       where
       some $tag2 in $e2/tag
       satisfies
       some $e in $O1
       satisfies
       some $tag in $e/tag 
       satisfies
       not(string(number($tag/@v)) != 'NaN') and
       not($tag/@v="yes") and
       not($tag/@v="no") and
       $tag2/@v=$tag/@v and not($tag/@k=$tag2/@k) return $e2) <= $delta
   else true()
};

(: TagsCOMPkvTest :)

declare function local:TagsCOMPkvTest($key,$epsilon,$delta,$rec)
{
if ($rec/k=$key) then ()
else
let $i1 := function($x){some $z in $x/tag satisfies $z/@k=$key}
let $O1 := local:M("*",$i1)
let $result := (
for $beta in $O1/tag[@k=$key]/@v
let $i2 := function($x){some $z in $x/tag satisfies ($z/@v=$beta)}
let $O2 := local:M("*",$i2)
return
if (not(local:TagsCOMPkv($O1,$O2,$epsilon,$delta)))
then $beta/../..)
return
if (empty($result)) then
local:TagsCOMPkvTestList($O1/tag/@k,$epsilon,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else $result
}; 

declare function local:TagsCOMPkvTestList($list,$epsilon,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:TagsCOMPkvTest(data(head($list)),$epsilon,$delta,$rec)
  return
  if (empty($result)) then local:TagsCOMPkvTestList(tail($list),$epsilon,$delta,$rec)
  else $result
};


(: TagsCOMPkk :)

declare function local:TagsCOMPkk($O1,$O2,$epsilon)
{
   count($O1 intersect $O2)>=$epsilon
};

(: TagsCOMPkkTest :)

declare function local:TagsCOMPkkTest($key,$epsilon,$rec)
{  
if ($rec/k=$key) then ()
else
let $i1 := function($x){$x[some $z in ./tag satisfies $z/@k=$key]}
let $O1 := local:M("*",$i1)
let $result :=
(for $beta in $O1/tag/@k
let $i2 := function($x){$x[some $z in ./tag satisfies $z/@k=$beta]}
let $O2 := local:M("*",$i2)
return
if (not(local:TagsCOMPkk($O1,$O2,$epsilon)))
then $beta/../..)
return
if (empty($result)) then
local:TagsCOMPkkTestList($O1/tag/@k,$epsilon,<list>{$rec/*,<k>{$key}</k>}</list>)
else $result
}; 

declare function local:TagsCOMPkkTestList($list,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:TagsCOMPkkTest(data(head($list)),$delta,$rec)
  return
  if (empty($result)) then local:TagsCOMPkkTestList(tail($list),$delta,$rec)
  else $result
};

(: TagsName :)

declare function local:TagsName($O1,$O2,$beta,$delta,$epsilon)
{
  if (count($O1)>=$delta) then
  let $i3 := function($x){$x[every $z in ./tag satisfies not($z/@v=$beta)]}
  let $O3 := local:M("*",$i3)
  where count($O2 intersect $O3)>=$epsilon
  return ($O2 intersect $O3)
};

(: TagsNameTest :)

declare function local:TagsNameTest($beta,$delta,$epsilon)
{
let $i1 := function($x){$x[some $z in ./tag satisfies $z/@v=$beta]}
let $O1 := local:M("*",$i1)
let $i2 := function($x){$x[some $z in ./tag satisfies contains(lower-case($z[@k="name"]/@v),lower-case($beta))]}
let $O2 := local:M("*",$i2)
return local:TagsName($O1,$O2,$beta,$delta,$epsilon)
}; 

(: NoDeadlock :)

declare function local:NoDeadlock($O1,$O2)
{
  every $w1 in $O1 
  satisfies
  every $w2 in $O1
      satisfies 
      $w1/@id=$w2/@id 
      or
      not($w1/nd[last()]/@ref = $w2/nd[last()]/@ref)
      or
      ($w1/nd[last()]/@ref = $w2/nd[last()]/@ref
      and 
      (some $w in $O2
      satisfies  
      ($w/nd/@ref = $w1/nd[last()]/@ref
      and not($w1/nd[last()]/@ref=$w/nd[last()]/@ref))))
};

(: NoDeadlockTest :)

declare function local:NoDeadlockTest($name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
              and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]  
              and (some $z in $x/tag satisfies $z[@k="highway"])})
  return if (not(local:NoDeadlock($O1,$O2)))
  then
  $O1
  else
  local:NoDeadlockTestList($O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,
  <list>{$rec/*,<n>{$name}</n>}</list>)
  
};

declare function local:NoDeadlockTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:NoDeadlockTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:NoDeadlockTestList(tail($list),$rec)
  else $result
};


(: NoIsolatedWay :)

declare function local:NoIsolatedWay($O1,$O2)
{
  some $w1 in $O1
  satisfies
  some $w2 in $O2
  satisfies 
  some $n in $w1/nd
  satisfies 
  some $m in $w2/nd
  satisfies    
  $n/@ref=$m/@ref
};

(: NoIsolatedWayTest :)

declare function local:NoIsolatedWayTest($name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(local:NoIsolatedWay($O1,$O2))) then
  $O1
  else 
  local:NoIsolatedWayTestList($O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,
  <list>{$rec/*,<n>{$name}</n>}</list>)
};


declare function local:NoIsolatedWayTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:NoIsolatedWayTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:NoIsolatedWayTestList(tail($list),$rec)
  else $result
};

(: ExitWay :)

declare function local:ExitWay($O1,$O2)
{
  some $w1 in $O1
  satisfies
  some $w2 in $O2
  satisfies
  some $n in $w1/nd
  satisfies
  some $m in $w2/nd
  satisfies
  ($n/@ref=$m/@ref
  and not($w2/nd[last()]/@ref=$m/@ref))
   
};

(: ExitWayTest :)

declare function local:ExitWayTest($name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(local:ExitWay($O1,$O2))) then
  $O1
  else 
  local:ExitWayTestList($O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{data($name)}</n>}</list>)
};

declare function local:ExitWayTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:ExitWayTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:ExitWayTestList(tail($list),$rec)
  else $result
};

(: EntranceWay :)

declare function local:EntranceWay($O1,$O2)
{
  some $w1 in $O1
  satisfies
  some $w2 in $O2
  satisfies
  some $n in $w1/nd 
  satisfies
  some $m in $w2/nd
  satisfies
  ($n/@ref=$m/@ref
  and not($w2/nd[1]/@ref=$m/@ref))
   
};

(: EntranceWayTest :)

declare function local:EntranceWayTest($name,$rec)

{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])})
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(local:EntranceWay($O1,$O2))) then
  $O1
  else 
  local:EntranceWayTestList($O2[(some $z in ./tag satisfies $z[@k="highway"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};


declare function local:EntranceWayTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:EntranceWayTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:EntranceWayTestList(tail($list),$rec)
  else $result
};

(: ExitRAbout :)

declare function local:ExitRAbout($O1,$O2)
{
  some $w1 in $O1
  satisfies
  (some $w2 in $O1[not((some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"]))] union $O2
  satisfies  
  some $n in $w1/nd
  satisfies
  $w2/nd[1]/@ref=$n/@ref)
  
   
};

(: ExitRAboutTest :)

declare function local:ExitRAboutTest($name,$rec)

{
  if ($rec/n=$name) then ()
  else
 let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"]) and (some $z in $x/tag satisfies $z[@k="junction" and @v="roundabout"])}) 
  let $O2 :=  local:M("way",function($x){(some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]
  and (some $z in $x/tag satisfies $z[@k="highway"]))})
  return
  if (not(empty($O1)) and (not(local:ExitRAbout($O1,$O2)))) then
  $O1
  else  
  local:ExitRAboutTestList($O2[
  (some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};


declare function local:ExitRAboutTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:ExitRAboutTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:ExitRAboutTestList(tail($list),$rec)
  else $result
};

(: EntRAbout :)

declare function local:EntRAbout($O1,$O2)
{
  some $w1 in $O1
  satisfies
  (some $w2 in $O1[not(some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"])] union $O2
  satisfies
  some $n in $w1/nd 
  satisfies
  $w2/nd[last()]/@ref=$n/@ref)
  
};

(: EntRAboutTest :)

declare function local:EntRAboutTest($name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"])  and (some $z in $x/tag satisfies $z[@k="junction" and @v="roundabout"])})  
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)
and (some $z in $x/tag satisfies $z[@k="highway"])]})
  return
  if  (not(empty($O1)) and (not(local:EntRAbout($O1,$O2)))) then
  $O1
  else 
  local:EntRAboutTestList($O2[  
(some $z in ./tag satisfies $z[@k="junction" and @v="roundabout"])]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function local:EntRAboutTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:EntRAboutTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:EntRAboutTestList(tail($list),$rec)
  else $result
};

(: Connected :)

declare function local:Connected($O1,$O2)
{
  every $w1 in $O1
  satisfies
  (
  some $w in $O1 union $O2
  satisfies
  (not($w/@id=$w1/@id)
  and
  (some $n in $w/nd satisfies
  ($w1/nd[last()])/@ref=$n/@ref))
  )
};

(: ConnectedTest :)

declare function local:ConnectedTest($name,$rec)
{
 if ($rec/n=$name) then ()
  else 
 let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
and (some $z in $x/tag satisfies $z[@k="highway"]) and not(some $z in $x/tag satisfies $z[@k="noexit" and @v="yes"])})
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]and 
  (some $z in $x/tag satisfies $z[@k="highway"])})
  return
  if (not(empty($O1)) and(not(local:Connected($O1,$O2)))) then
  $O1
  else  
  local:ConnectedTestList($O2[not(some $z in ./tag satisfies $z[@k="noexit" and @v="yes"])]/tag[@k="name"]/@v,
  <list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function local:ConnectedTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:ConnectedTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:ConnectedTestList(tail($list),$rec)
  else $result
};

(: memberLine: node-nodes :)

declare function local:memberLine($x,$n1,$n2)
{
  local:memberLineP(local:Lat($x),local:Lon($x),local:Lat($n1),local:Lon($n1),local:Lat($n2),local:Lon($n2))
  
};

(: memberLineP: points-points :)

declare function local:memberLineP($x,$y,$x1,$y1,$x2,$y2)
{
  
  if ((($y - $y1) * ($x2 - $x1)) - (($y2 - $y1) * ($x - $x1)) =0 )
  then true()
  else false()
  
};

(: overlapLine: nodes-nodes :)

declare function local:overlapLine($n1,$n2,$n3,$n4)
{
    local:memberLine($n1,$n3,$n4) and local:memberLine($n2,$n3,$n4)

};

(: intersectionLine: nodes-nodes :)

declare function local:intersectionLine($n1,$n2,$n3,$n4)
{
  local:intersectionLineP(local:Lat($n1),local:Lon($n1),local:Lat($n2),
  local:Lon($n2),local:Lat($n3),local:Lon($n3),local:Lat($n4),local:Lon($n4))
  
};

(: intersectionLine points-points :)

declare function local:intersectionLineP($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)
{
  
 if (((($x1 - $x2) * ($y3 - $y4)) - (($y1 - $y2) * ($x3 - $x4)))=0)
 then ()
 else 
 let $t := 
     ((($x1 - $x3)*($y3 - $y4)) - (($y1 - $y3)*($x3 - $x4)))
     div 
     ((($x1 - $x2)*($y3 - $y4)) - (($y1 - $y2)*($x3 - $x4)))
 return ($x1 + $t*($x2 - $x1), $y1 + $t*($y2 - $y1))
  
};



(: memberSegment: node-nodes :)

declare function local:memberSegment($n,$n1,$n2)
{
  local:memberSegmentP(local:Lat($n),local:Lon($n),local:Lat($n1),local:Lon($n1),local:Lat($n2),local:Lon($n2))
  
};

(: memberSegmentPoint: points-nodes :)

declare function local:memberSegmentPoint($x1,$x2,$n1,$n2)
{
  local:memberSegmentP($x1,$x2,local:Lat($n1),local:Lon($n1),local:Lat($n2),local:Lon($n2))
  
};

(: memberSegmentP: point-points :)

declare function local:memberSegmentP($x,$y,$x1,$y1,$x2,$y2)
{  
  if 
  (
  (math:sqrt(math:pow($x - $x1,2) + math:pow($y - $y1,2)) +
  math:sqrt(math:pow($x - $x2,2) + math:pow($y - $y2,2))) -
  math:sqrt(math:pow($x1 - $x2,2) + math:pow($y1 - $y2,2)) <= 0
  )
  then true()
  else false()
  
  
};

(: overlapSegment: nodes-nodes :)

declare function local:overlapSegment($n1,$n2,$n3,$n4)
{
   
local:overlapLine($n1,$n2,$n3,$n4) and 
       (local:memberSegment($n1,$n3,$n4) or local:memberSegment($n2,$n3,$n4))


};

(: intersectionSegment: nodes-nodes :)

declare function local:intersectionSegment($n1,$n2,$n3,$n4)
{
  local:intersectionSegmentP(local:Lat($n1),local:Lon($n1),local:Lat($n2),local:Lon($n2),local:Lat($n3),local:Lon($n3),local:Lat($n4),local:Lon($n4))
  
};




(: intersectionSegment: points-points :)

declare function local:intersectionSegmentP($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)
{
  let $s := local:intersectionLineP($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4)
  return 
  if (empty($s)) then ()
  else
  if (local:memberSegmentP($s[1],$s[2],$x1,$y1,$x2,$y2)) then $s
  else ()
  
};


(: AreaNoInt :)


declare function local:AreaNoInt($O1,$O2)
{
  every $w1 in $O1
  satisfies
  every $w2 in $O2
  satisfies  
  $w2/tag/@k="highway"
  or
  $w2/tag/@k="waterway"
  or
  $w2/tag/@k="railway"
  or
  (every $n2 in $w1/nd
   satisfies
   every $n2p in $w2/nd
   satisfies
   let $n1 := ($n2/preceding-sibling::node())[last()]
   let $n1p := ($n2p/preceding-sibling::node())[last()] 
   let $p := local:intersectionLine(local:Node($n1),local:Node($n2),local:Node($n1p),local:Node($n2p))
   return 
   (local:memberLine(local:Node($n1),local:Node($n1p),local:Node($n2p))
   and
   local:memberLine(local:Node($n2),local:Node($n1p),local:Node($n2p))
   ) 
   or
   empty($p)
   or
   (not(local:memberSegmentPoint($p[1],$p[2],local:Node($n1),local:Node($n2))) 
    or 
    not(local:memberSegmentPoint($p[1],$p[2],local:Node($n1p),local:Node($n2p)))
   )
   )
  
};

 

declare function local:AreaNoIntTest($name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
  and ((some $z in $x/tag satisfies $z[@k="area" and@v="yes"])
  or (some $z in $x/tag satisfies $z[@k="building"])
  or (some $z in $x/tag satisfies $z[@k="landuse"]))
  })
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]})
  return
  if (not(empty($O1)) and (not(local:AreaNoInt($O1,$O2)))) then $O1
  else local:AreaNoIntTestList($O2[(some $z in ./tag satisfies $z[@k="area" and@v="yes"])
  or (some $z in ./tag satisfies $z[@k="building"])
  or (some $z in ./tag satisfies $z[@k="landuse"])
  ]/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function local:AreaNoIntTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:AreaNoIntTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:AreaNoIntTestList(tail($list),$rec)
  else $result
};


declare function local:NoOverlap($O1,$O2)
{
  every $w1 in $O1
  satisfies
  every $w2 in $O2
  satisfies 
  (every $n2 in $w1/nd
  satisfies
  every $n2p in $w2/nd
  satisfies
  let $n1 := ($n2/preceding-sibling::node())[last()]
  let $n1p := ($n2p/preceding-sibling::node())[last()] 
  return
  not(local:overlapSegment(local:Node($n1),local:Node($n2),local:Node($n1p),local:Node($n2p)))
  )
};

declare function local:NoOverlapTest($name,$rec)
{
  if ($rec/n=$name) then ()
  else
  let $O1 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and @v=$name]
  and (some $z in $x/tag  satisfies ($z/@k="building" or $z/@k="highway"))})
  let $O2 :=  local:M("way",function($x){some $z in $x/tag satisfies $z[@k="name"and not(@v=$name)]
  and (some $z in $x/tag  satisfies ($z/@k="building" or $z/@k="highway"))})
  return
  if (not(local:NoOverlap($O1,$O2))) then
  $O1
  else  
  local:NoOverlapTestList($O2/tag[@k="name"]/@v,<list>{$rec/*,<n>{$name}</n>}</list>)
};

declare function local:NoOverlapTestList($list,$rec)
{
  if (empty($list)) then ()
  else
  let $result := local:NoOverlapTest(data(head($list)),$rec)
  return
  if (empty($result)) then local:NoOverlapTestList(tail($list),$rec)
  else $result
};




(:
local:TagsCOMPkvTest("building",1,1,())
:)

(:
local:TagsCOMPkkTest("amenity",2,())
:)

(:local:TagsNameTest("hotel",1,0):)

(:
local:NoDeadlockTest("Calle Calzada de Castro",())
:)

(:
local:NoIsolatedWayTest("Calle Calzada de Castro",())
:)

(:
local:ExitRAboutTest("Calle Calzada de Castro",())
:)

(:
local:EntRAboutTest("Calle Calzada de Castro",())
:)

(:
local:ConnectedTest("Calle Calzada de Castro",())
:)

(:
local:AreaNoIntTest("Calle de Alerce",())
:)

(:
local:NoOverlapTest("Estación de Almería",())
:)

 