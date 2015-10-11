
#include <string>
#include <vector>
#include <fstream>
#include <iostream>

namespace stretch {



struct lammps_input_atom {
    int atom_id;
    int atom_type;
    double pos_x;
    double pos_y;
    double pos_z;
};

struct coords {
    double x;
    double y;
    double z;
};

struct lammps_simulation_box {
    double xlo,xhi,ylo,yhi,zlo,zhi,Lx,Ly,Lz;
};


std::vector <lammps_input_atom> atom_vector_from_file (const char * input_filename) {
    std::vector<lammps_input_atom> atoms;
    std::ifstream LAMMPS_input (input_filename, std::ifstream::in);
    std::string line_in;

    int atoms_indexed=0;
    int num_atoms=0;

    std::getline(LAMMPS_input,line_in);
    std::getline(LAMMPS_input,line_in);

    LAMMPS_input >> num_atoms;

    std::cout << "[STRETCH] Atoms in LAMMPS input file: "
                << num_atoms
                << std::endl;

    std::string read_word;
    while ( !LAMMPS_input.eof() )
    {
        LAMMPS_input >> read_word;
        if (read_word == "Atoms")
            break;
    }

    int atom_id, atom_type;
    double x0,x1,x2;

    while ( !LAMMPS_input.eof() && atoms_indexed < num_atoms )
    {
        LAMMPS_input >> atom_id;
        LAMMPS_input >> atom_type;
        LAMMPS_input >> x0;
        LAMMPS_input >> x1;
        LAMMPS_input >> x2;
        lammps_input_atom new_atom = {atom_id,atom_type,x0,x1,x2};
        atoms.push_back(new_atom);
        ++atoms_indexed;
    }

    //logput << "Loaded " << atoms_indexed << " carbons in "
    //        << std::setprecision(6)
    //        << (double)(atoms_indexed * sizeof(lammps_input_atom))
    //                                  / 1024 / 1024 << " MB." 
    //        << std::endl;
    
    return atoms;
}



//  Reads LAMMPS input data file, returns the file's box.
lammps_simulation_box lammps_box_from_file (const char * input_filename) {
    std::ifstream LAMMPS_input (input_filename, std::ifstream::in);
    std::string read_word;
    lammps_simulation_box box;
    std::string str;

    while ( !LAMMPS_input.eof() )
    {
        LAMMPS_input >> read_word;
        if (read_word == "types")
            break;
    }

    LAMMPS_input >> box.xlo >> box.xhi >> str >> str
                 >> box.ylo >> box.yhi >> str >> str
                 >> box.zlo >> box.zhi;

                box.Lx = box.xhi - box.xlo;
                box.Ly = box.yhi - box.ylo;
                box.Lz = box.zhi - box.zlo;

    std::cout << "[STRETCH] Simulation box dimensions: "
                << box.xlo << " "
                << box.xhi << " "
                << box.ylo << " "
                << box.yhi << " "
                << box.zlo << " "
                << box.zhi << " "
                << std::endl;

    return box;
}


//  Takes a box, returns a new box with stretch sides per delta-x/Lx.
//
//

lammps_simulation_box perform (lammps_simulation_box prestretch,
                                    double delta_x = 0.0,
                                    double delta_y = 0.0,
                                    double delta_z = 0.0) {
    lammps_simulation_box stretched;
    stretched.xlo = prestretch.xlo;
    stretched.ylo = prestretch.ylo;
    stretched.zlo = prestretch.zlo;
    stretched.xhi = prestretch.xhi + delta_x;
    stretched.yhi = prestretch.yhi + delta_y;
    stretched.zhi = prestretch.zhi + delta_z;
    stretched.Lx = stretched.xhi - stretched.xlo;
    stretched.Ly = stretched.yhi - stretched.ylo;
    stretched.Lz = stretched.zhi - stretched.zlo;
    return stretched;
}

} // end namespace stretch


int main() {
    const char * input_filename = "prestretch.input";
    const char * new_input_filename = "stretched.input";
    const char * param_filename = "strain_params";

    // Read parameters.
    std::cout << "[STRETCH] Preparing program." << std::endl;
    double Lx0,Ly0,Lz0,dx_scaled,dy_scaled,dz_scaled,dx,dy,dz;
    std::ifstream param_file(param_filename);
    param_file >> Lx0 >> Ly0 >> Lz0 >> dx_scaled >> dy_scaled >> dz_scaled;
    dx=Lx0*dx_scaled;
    dy=Ly0*dy_scaled;
    dz=Lz0*dz_scaled;

    // Read simulation box info.
    stretch::lammps_simulation_box box
                = stretch::lammps_box_from_file(input_filename);
    stretch::coords box_origin = {box.xlo, box.ylo, box.zlo};

    // Create stretched box.
    stretch::lammps_simulation_box stretched_box;
    stretched_box = stretch::perform(box,dx,dy,dz);
    stretch::coords stretched_box_origin = {stretched_box.xlo,
                                             stretched_box.ylo,
                                             stretched_box.zlo};    

    // Read atomic data.
    std::vector<stretch::lammps_input_atom> atoms;
    atoms = stretch::atom_vector_from_file (input_filename);
    int num_atoms=atoms.size();

    // Transform atom positions to scaled coordinates.
    std::cout << "[STRETCH] Transforming coordinates." << std::endl;
    stretch::coords primed;
    std::vector<stretch::coords> shifted;
    for (int i=0; i<num_atoms; ++i) {
        primed.x = atoms[i].pos_x - box_origin.x;
        primed.y = atoms[i].pos_y - box_origin.y;
        primed.z = atoms[i].pos_z - box_origin.z;
        shifted.push_back(primed);
    }

    stretch::coords transformed;
    std::vector<stretch::coords> scaled;
    for (int i=0; i<num_atoms; ++i) {
        transformed.x = shifted[i].x / box.Lx;
        transformed.y = shifted[i].y / box.Ly;
        transformed.z = shifted[i].z / box.Lz;
        scaled.push_back(transformed);
    }


    // Remap atomic cartesian coordinates using new box size.
    std::cout << "[STRETCH] Remapping coords." << std::endl;
    stretch::coords remap_unshift;
    std::vector<stretch::coords> remapped_unshifted;
    for (int i=0; i<num_atoms; ++i) {
        remap_unshift.x = (scaled[i].x * stretched_box.Lx)
                                    + stretched_box_origin.x;
        remap_unshift.y = (scaled[i].y * stretched_box.Ly)
                                    + stretched_box_origin.y;
        remap_unshift.z = (scaled[i].z * stretched_box.Lz)
                                    + stretched_box_origin.z;
        remapped_unshifted.push_back(remap_unshift);
    }

    // New vector of input atoms for new LAMMPS input file.
    std::cout << "[STRETCH] Writing new vector." << std::endl;
    stretch::lammps_input_atom stretched_atom;
    std::vector<stretch::lammps_input_atom> stretched_atoms;
    for (int i=0; i<num_atoms; ++i) {
        stretched_atom = {atoms[i].atom_id,1,
                            remapped_unshifted[i].x,
                            remapped_unshifted[i].y,
                            remapped_unshifted[i].z};
        stretched_atoms.push_back(stretched_atom);

    }


    // Output new LAMMPS input file.
    std::cout << "[STRETCH] Writing new LAMMPS input file." << std::endl;
    std::ofstream new_file(new_input_filename);

    new_file << "LAMMPS input file created using OAU stretch program."
                << std::endl << std::endl << num_atoms << "atoms"
                << std::endl << std::endl << std::endl
                << "1 atom types" << std::endl << std::endl;
        

    new_file    << stretched_box.xlo <<" "<< stretched_box.xhi <<" "
                << "xlo" <<" "<< "xhi" << std::endl
                << stretched_box.ylo <<" "<< stretched_box.yhi <<" "
                << "ylo" <<" "<< "yhi" << std::endl
                << stretched_box.zlo <<" "<< stretched_box.zhi <<" "
                << "zlo" <<" "<< "zhi" << std::endl
                << std::endl << std::endl;

    new_file    << "Masses" << std::endl << std::endl
                << "1 12.01" << std::endl << std::endl
                << "Atoms" << std::endl << std::endl;

    for (int i=0; i<num_atoms; ++i) {
        new_file    << stretched_atoms[i].atom_id <<" "
                    << stretched_atoms[i].atom_type <<" "
                    << stretched_atoms[i].pos_x <<" "
                    << stretched_atoms[i].pos_y <<" "
                    << stretched_atoms[i].pos_z << std::endl;
    }

//    for (int i=0; i<num_atoms; ++i) {
//        new_file    << atoms[i].atom_id <<" "
//                    << atoms[i].atom_type <<" "
//                    << atoms[i].pos_x <<" "
//                    << atoms[i].pos_y <<" "
//                    << atoms[i].pos_z << std::endl;
//    }

    new_file.flush();
    new_file.close();

    return 0;
}