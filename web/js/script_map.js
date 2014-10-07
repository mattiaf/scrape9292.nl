
colorconnection='#FFF0A5'

var domaintime=[0, 60, 120, 180]
  var colortime = d3.scale.linear()
    	.domain(domaintime).range(colorbrewer.YlGn[4].reverse())
 //   	.range(["forestgreen", "limegreen", "yellow",  "red"]);
//		.range(["#ffffcc" , "#41b6c4", "#a1dab4", "#225ea8"]);



var domainchanges=[0, 1, 2,3 ]

  var colorchanges = d3.scale.linear()
    	.domain(domainchanges)
    	//.range(colorbrewer.RdYlGn[4].reverse())
   	.range(["forestgreen", "yellow", "orange",  "red"]);
//		.range(["#ffffcc" , "#41b6c4", "#a1dab4", "#225ea8"]);


var width = document.getElementById('container').width;
var height =document.getElementById('container').height; //width / 2;

width=655;
height=800;


var graticule = d3.geo.graticule();

var topo,projection,path,svg,g;

var tooltip = d3.select("#container").append("div").attr("class", 'tooltip hidden');

setup(width,height);
function setup(width,height){
	projection = d3.geo.mercator()  //geo.mercator  .translate([(width/2), (height/2)])//  
	  .center([6.3, 52.7 ])
	  .scale(9000) // 600 europe
	  .rotate([0,0]);
	
	path = d3.geo.path().projection(projection);
	svg = d3.select("#container").append("svg")
	      .attr("width", width)
	      .attr("height", height);
	      
	g = svg.append("polygon")
		.attr("points","0,800 0,595 150,595 500,300 570,45 680,0 680,800")      
		.attr("style","fill:#ddd")      


	
	g = svg.append("g");
}

    

d3.json("js/topojsonsuperlowprecision.json", function(error, world) {
  var countries = topojson.feature(world, world.objects.countries).features;

  topo = countries;
  
  draw(topo); //draw maps with colors

	
 

}); //end d3.json





function draw(topo) {

 	d3.csv("scrapeddata.csv", function(error, csvtable) {
		       		

  var country = g.selectAll(".country").data(topo);




  paths = country.enter().insert("path")
      .attr("id", function(d,i) { return ''+d.properties.GM_NAAM ; })
      .attr("class", "country")
      .attr("d", path)
      .attr("title", function(d,i) { return d.properties.GM_NAAM; })
      .style("fill", '#000000');

 var metric = document.getElementById('metric').selectedOptions[0].value;
   g.selectAll("path")
      .attr("timeinminutes", function(d,i) {
						     	return csvtable[i].timeinminutes;
						      	})
       .style("fill", function(d,i) {
       	if (metric == 'timeinminutes'){
       		
       	return colortime(csvtable[i].timeinminutes)
       	
       	} 
       	if (metric == 'nchanges'){return colorchanges(csvtable[i].nchanges)} 
        
        } )      	
       	
       .attr("mm", function(d,i) { return csvtable[i].timeinminutes % 60 }) // storing minutes
       .attr("hh", function(d,i) { return (csvtable[i].timeinminutes-csvtable[i].timeinminutes % 60) / 60 }) // storing hours
       .attr("nchanges", function(d,i) { return csvtable[i].nchanges}); // storing minutes


    addpoint(4.7642,52.3081, '' ); //goodway to add points third name is variable

     //offsets for tooltips
	 var offsetL = document.getElementById('container').offsetLeft+20;
	 var offsetT = document.getElementById('container').offsetTop+10;
   
    paths.on("mouseover", function(d,i) {
		    var idcenter = d.id 
		    var mouse = d3.mouse(svg.node()).map( function(d) { return parseInt(d); } );
			       d3.select(this).attr("class","highlight"); //if you want to highlight that
		
			thisid = d3.select(this).attr("id") 
			thisminutes = d3.select(this).attr("mm") 
			thishours = d3.select(this).attr("hh") 
			thischanges = d3.select(this).attr("nchanges") 
		
		    tooltip.classed("hidden", false)
		             .attr("style", "left:"+(mouse[0]+offsetL)+"px;top:"+(mouse[1]+offsetT)+"px")
		             .html(function(d) {
				             	if (thisminutes < 10){return thisid + ' <br> ' + thishours + ':0' + thisminutes + ' to the airport <br>' + thischanges + ' stopover(s)' } // formatting minutes
				                else {return thisid + ' <br> ' + thishours + ':' + thisminutes + ' to the airport <br>' + thischanges + ' stopover(s)' }
						             }); // end html modification
             
    	     }) // end mouseon    	

   
    paths.on("mouseout", function(d,i) {
    		d3.select(this).attr("class","country"); //if you want to highlight that

		    tooltip.attr("class", 'tooltip hidden');
             }) // end mouseon    	

var legend=g.append("legend")


if (metric == 'timeinminutes'){var colorlegend = colortime; var domainlegend = domaintime ; var nn=16, shift=2; var suffix='min'} 
if (metric == 'nchanges'){var  colorlegend =colorchanges ; var domainlegend = domainchanges; var nn=3, shift=10; var suffix=''}


var heightlegend  =100
var sizey = heightlegend/(nn)
var ytext = sizey/(4-1)*0.95

g.append("svg:rect")
		.attr("x",50+28)
		.attr("y",00)
		.attr("height",heightlegend+100)
		.attr("width",60)
		.attr("fill","#ADD8E6")


keys = legend.selectAll("key").data(colorlegend.range())

rangecols=d3.range(0,d3.max(domainlegend)/3*4, d3.max(domainlegend)/(nn))
var legendtext= g.selectAll("key").data(colorchanges.range()).enter().append("svg:text") // text
		.attr("x",50+28)
		.attr("y",function(d,i){return 50+heightlegend-i*heightlegend/(3) - shift})
		.attr("height",heightlegend)
		.attr("width",25)
		.attr("font-size","15pt")
		
legendtext.html(function(d,i){
	if (i==3){return domainlegend[i] + '+'}
	if (i!=3){return domainlegend[i]}

	})

g.selectAll("key").data(rangecols).enter().append("svg:rect") //for continuus values
		.attr("x",50)
		.attr("y",function(d,i){return 50+heightlegend-sizey-i*sizey})
		.attr("height",sizey)
		.attr("width",25)
     	 .attr("fill", function(d,i){return colorlegend(rangecols[i])})


 


       	
	});  //END OF CSV

} // end of function draw(topo)

function addpoint(lat,lon,text) {

  var x = projection([lat,lon])[0];
  var y = projection([lat,lon])[1];
  var gpoint = g.append("svg:circle")
        .attr("cx", x)
        .attr("cy", y)
        .attr("r", "7pt")
      .attr("fill", "blue")

  var gpoint = g.append("svg:circle")
        .attr("cx", x)
        .attr("cy", y)
        .attr("r", "5pt")
      .attr("fill", "#fff")

  var gpoint = g.append("svg:circle")
        .attr("cx", x)
        .attr("cy", y)
        .attr("r", "3pt")
      .attr("fill", "red")

  //conditional in case a point has no associated text
  if(text.length>0){
    gpoint.append("text")
          .attr("x", x+2)
          .attr("y", y+2)
          .attr("class","text")
          .text(text);
  }

} //end addpoint



