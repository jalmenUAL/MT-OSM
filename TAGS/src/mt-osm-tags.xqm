module namespace mt = 'mt';


(: M :)

declare function mt:M($map,$type,$cond)
{
  filter($map/osm/*,function($e){mt:type($e,$type) and $cond($e)})
};

(: Node :)

declare function mt:Node($map,$nd)
{
  let $ref := data($nd/@ref)
  return $map/osm/node[@id=$ref]
};

(: Lat :)

declare function mt:Lat($nd)
{
  data($nd/@lat)
};

(: Lon :)

declare function mt:Lon($nd)
{
  data($nd/@lon)
};

(: type :)

declare function mt:type($e,$type)
{
  if ($type="*") then name($e)="node" or name($e)="way"
  else if ($type="node") then name($e)="node"
  else name($e)="way"
};



 



(: TagsMISSkvk :)

declare function mt:TagsMISSkvk($alpha,$O2,$O3,$O3O,$delta,$epsilon)
{
   if (count($O2 intersect $O3O) >= $delta)
   then 
   count($O2 intersect $O3) <= $epsilon
   else true()
};
 


declare function mt:TagsMISSkvkTest($map,$key,$epsilon,$delta,$rec)
{
if ($rec/k=$key) then ()
else
let $i1 := function($x){some $z in $x/tag satisfies $z/@k=$key}
let $O1 := mt:M($map,"*",$i1)
let $result := (
let $Aux := $O1/tag[@k=$key]
for $beta in distinct-values($Aux/@v)
let $i2 := function($x){some $z in $x/tag satisfies ($z/@k=$key and $z/@v=$beta)}
let $O2 := mt:M($map,"*",$i2)
for $alphap in distinct-values($Aux/@v/../../tag/@k)
where not($alphap=$key)
let $i3 := function($x){some $z in $x/tag satisfies ($z/@k=$alphap)}
let $O3 := mt:M($map,"*",$i3)
let $i3O := function($x){every $z in $x/tag satisfies not($z/@k=$alphap)}
let $O3O := mt:M($map,"*",$i3O)
return
if (not(mt:TagsMISSkvk($key,$O2,$O3,$O3O,$epsilon,$delta)))
then <error>{($O2 intersect $O3O) union <total>{count(($O2 intersect $O3O))}</total> union <alpha>{$key}</alpha> union <beta>{data($beta)}</beta> union <alphap>{data($alphap)}</alphap>}
</error>)
return
if (empty($result)) then
mt:TagsMISSkvkTestList($map,$O1/tag/@k,$epsilon,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else  $result
}; 

declare function mt:TagsMISSkvkTestList($map,$list,$epsilon,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:TagsMISSkvkTest($map,data(head($list)),$epsilon,$delta,$rec)
  return
  if (empty($result)) then mt:TagsMISSkvkTestList($map,tail($list),$epsilon,$delta,$rec)
  else $result
};



(: TagsCOMPkvk :)

declare function mt:TagsCOMPkvk($alpha,$O2,$O3,$delta,$epsilon)
{
   if (count($O2) >= $delta)
   then 
   count($O2 intersect $O3)>=$epsilon
   else true()
};
 


declare function mt:TagsCOMPkvkTest($map,$key,$epsilon,$delta,$rec)
{
if ($rec/k=$key) then ()
else
let $i1 := function($x){some $z in $x/tag satisfies $z/@k=$key}
let $O1 := mt:M($map,"*",$i1)
let $result := (  
for $beta in $O1/tag[@k=$key]/@v
let $i2 := function($x){some $z in $x/tag satisfies ($z[@k=$key and @v=$beta])}
let $O2 := mt:M($map,"*",$i2)
for $alphap in $beta/../../tag/@k
where not($alphap=$key)
let $i3 := function($x){some $z in $x/tag satisfies ($z/@k=$alphap)}
let $O3 := mt:M($map,"*",$i3)
return
if (not(mt:TagsCOMPkvk($key,$O2,$O3,$epsilon,$delta)))
then <error>{($O2 intersect $O3) union <total>{count($O2 intersect $O3)}</total> union <alpha>{$key}</alpha> union <beta>{data($beta)}</beta> union <alphap>{data($alphap)}</alphap>}
</error>)
return
if (empty($result)) then
mt:TagsCOMPkvkTestList($map,$O1/tag/@k,$epsilon,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else  $result   

}; 

declare function mt:TagsCOMPkvkTestList($map,$list,$epsilon,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:TagsCOMPkvkTest($map,data(head($list)),$epsilon,$delta,$rec)
  return
  if (empty($result)) then mt:TagsCOMPkvkTestList($map,tail($list),$epsilon,$delta,$rec)
  else $result
};



(: TagsCOMPkv :)
 
declare function mt:TagsCOMPkv($alpha,$beta,$O1p,$O2,$delta,$epsilon)
{
   if (count($O1p) >= $delta)
   then
   every $alphap in $O2/tag[@v=$beta]/@k 
   satisfies
   $alpha=$alphap
   or 
   $alphap="name"
   or
   $alphap="addr:street" 
   or 
   count(
   for $ep in $O2
   where
    $ep/tag[@k=$alphap and @v=$beta]
    and
     not(string(number($beta)) != 'NaN') and
       not($beta="yes") and
       not($beta="no") 
   return $ep) <= $epsilon
   else true()
};
 


declare function mt:TagsCOMPkvTest($map,$key,$epsilon,$delta,$rec)
{
if ($rec/k=$key) then ()
else
let $i1 := function($x){some $z in $x/tag satisfies $z/@k=$key}
let $O1 := mt:M($map,"*",$i1)
let $result := (
let $Aux := $O1/tag[@k=$key]
for $beta in distinct-values($Aux/@v)
let $i1p := function($x){some $z in $x/tag satisfies ($z/@k=$key and $z/@v=$beta)}
let $O1p := mt:M($map,"*",$i1p)
let $i2 := function($x){some $z in $x/tag satisfies ($z/@v=$beta)}
let $O2 := mt:M($map,"*",$i2)
return
if (not(mt:TagsCOMPkv($key,$beta,$O1p,$O2,$epsilon,$delta)))
then 
let $conflict :=
for $alphap in $O2/tag[@v=$beta]/@k 
   where   
   count(
   for $ep in $O2
   where
    $ep/tag[@k=$alphap and @v=$beta]
    and
     not(string(number($beta)) != 'NaN') and
       not($beta="yes") and
       not($beta="no") 
   return $ep) > $epsilon
   return data($alphap)
return
<error>{($O1p) union <total>{count($O1p)}</total> union <alpha>{$key}</alpha> union <beta>{data($beta)}</beta> union <conflict>{distinct-values($conflict)}</conflict>}
</error>)
return
if (empty($result)) then
mt:TagsCOMPkvTestList($map,$O1/tag/@k,$epsilon,$delta,<list>{$rec/*,<k>{$key}</k>}</list>)
else  $result  
}; 


declare function mt:TagsCOMPkvTestList($map,$list,$epsilon,$delta,$rec)
{
  if (empty($list)) then ()
  else
  let $result := mt:TagsCOMPkvTest($map,data(head($list)),$epsilon,$delta,$rec)
  return
  if (empty($result)) then mt:TagsCOMPkvTestList($map,tail($list),$epsilon,$delta,$rec)
  else $result
};


 


(: TagsName :)

declare function mt:TagsName($map,$O1,$O2,$beta,$delta,$epsilon)
{
  if (count($O1)>=$delta) then
  let $i3 := function($x){$x[every $z in ./tag satisfies not($z/@v=$beta)]}
  let $O3 := mt:M($map,"*",$i3)
  where count($O2 intersect $O3)>$epsilon
  return ($O2 intersect $O3)
};


declare function mt:TagsNameTest($map,$beta,$delta,$epsilon)
{
let $i1 := function($x){$x[some $z in ./tag satisfies $z/@v=$beta]}
let $O1 := mt:M($map,"*",$i1)
let $i2 := function($x){$x[some $z in ./tag satisfies contains(lower-case($z[@k="name"]/@v),lower-case($beta))]}
let $O2 := mt:M($map,"*",$i2)
return mt:TagsName($map,$O1,$O2,$beta,$delta,$epsilon)
}; 





 