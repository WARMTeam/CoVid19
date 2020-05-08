/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* Author: Kevin Chapuis
* Tags: covid19,epidemiology
******************************************************************/

model Buildingsfrompoints


global {
	
	string dataset_path <- "../External Datasets/Domiz - refugee camp/";
	
	// Blocks
	file building_blocks_file <- file(dataset_path+ "Domiz_Shelters_block.shp");
	file building_bounds_file <- file(dataset_path+ "boundary.shp");
	// Roads (to define block with when no one wants to digitalize the area)
	string roads_file;
	geometry shape <- envelope(building_bounds_file);
	// Mandatory
	file building_points_file <- file(dataset_path+ "Domiz_Shelters.shp");
	
	// Parameter to choose to fit inside or overflows outside building_blocks_file
	bool overflow <- false;
	
	// Output
	string output_building_file_path <- dataset_path+"buildings.shp";
	
	bool DEBUG <- true;
	
	init {
		
		create building_point from:shape_file(building_points_file);
		create building_block from:shape_file(building_blocks_file);
		
		if file_exists(dataset_path+"satellite.png") { write "background image should be ok";}
		
		if DEBUG {write "There is "+length(building_block)+" building blocks";}
		
		ask building_point {
			building_block bb <- building_block overlapping self;
			if bb=nil { bb <- first(building_block sort_by (each.shape.centroid distance_to self)); }  
			bb.linked_points <+ self;
		}
		
		if DEBUG {write "There is "+length(building_point)+" building points ("+sum(building_block collect (length(each.linked_points)))+")";}
		
		ask building_block where not(empty(each.linked_points)) {
			list<geometry> sub_blocks <- self.shape to_squares (length(linked_points),overflow);
			if length(sub_blocks) != length(linked_points) {error "Does not create the proper number of building from points";}
			loop sb over:sub_blocks {create output_building with:[shape::sb];}
		}
		
		ask output_building { 
			related <- building_point closest_to self;
			self.shape.attributes <<+ related.shape.attributes;
		}
		
		if DEBUG {
			output_building rnd_output <- any(output_building); 
			write sample(rnd_output.shape.attributes);
			write sample(rnd_output.related.shape.attributes);
		}
		
		save output_building to:output_building_file_path type:shp;
		
	}
	
}

species building_block {
	list<building_point> linked_points; 
	aspect default {draw shape color:#grey; draw string(length(linked_points)) at:shape.centroid font:font(5) color:#white;}
}

species building_point { aspect default {draw circle(1) color:#red;}} 

species output_building {
	building_point related; 
	aspect default {draw shape.contour buffer 1 color:#white;}
} 

experiment xp {
	output {
		display map type: opengl draw_env: false background: #black {
			image (file_exists(dataset_path+"satellite.png") ? (dataset_path+"satellite.png"): "white.png")  transparency: 0.2;
			species building_block;
			species output_building;
			species building_point;
		}
	}
}