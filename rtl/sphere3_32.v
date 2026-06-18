module sphere3_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [31:0] x,
    output wire [31:0] y,
    output wire [31:0] z,
    output wire [31:0] w,
    output reg        valid
);

    // VdC<7> for the 3-sphere latitude angle
    wire [31:0] vdc7_out;
    wire        vdc7_valid;
    vdc_7_ilds_32 u_vdc7 (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .vdc_out(vdc7_out),
        .valid (vdc7_valid)
    );

    // Sphere<2,3> for the 2-sphere cross-section
    wire [31:0] sx, sy, sz;
    wire        sphere_valid;
    sphere_32 u_sphere (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .x     (sx),
        .y     (sy),
        .z     (sz),
        .valid (sphere_valid)
    );

    // LUT: map VdC<7> output to angle_xi (cordic_32 input format)
    // VdC<7> output is VdC * 7^11, max = 1977326742 (31-bit unsigned)
    // Scale factor maps [0, VDC7_MAX] to [0, 256]:
    // scale = floor(256 * 2^32 / VDC7_MAX) = 556
    wire [41:0] scaled = vdc7_out * 42'd556;
    wire [7:0]  lut_idx = scaled[39:32];
    wire [31:0] frac = {scaled[31:0]};

    reg [31:0] angle_lut [0:256];
    initial begin
        angle_lut[  0]=32'h00000000; angle_lut[  1]=32'h0ACE3220; angle_lut[  2]=32'h0DA7A472; angle_lut[  3]=32'h0FAAAFEB;
        angle_lut[  4]=32'h1147F222; angle_lut[  5]=32'h12A7146E; angle_lut[  6]=32'h13DBDD83; angle_lut[  7]=32'h14F1DE0D;
        angle_lut[  8]=32'h15EF4FB1; angle_lut[  9]=32'h16D9C042; angle_lut[ 10]=32'h17B49A5B; angle_lut[ 11]=32'h18826417;
        angle_lut[ 12]=32'h19452B35; angle_lut[ 13]=32'h19FDBEB4; angle_lut[ 14]=32'h1AAE23E9; angle_lut[ 15]=32'h1B5742A8;
        angle_lut[ 16]=32'h1BF97106; angle_lut[ 17]=32'h1C95E95F; angle_lut[ 18]=32'h1D2D01AA; angle_lut[ 19]=32'h1DBF04CE;
        angle_lut[ 20]=32'h1E4CD91A; angle_lut[ 21]=32'h1ED6ACD1; angle_lut[ 22]=32'h1F5C674D; angle_lut[ 23]=32'h1FDECC82;
        angle_lut[ 24]=32'h205E1109; angle_lut[ 25]=32'h20DA65A9; angle_lut[ 26]=32'h2153F7A6; angle_lut[ 27]=32'h21CAF109;
        angle_lut[ 28]=32'h223F7857; angle_lut[ 29]=32'h22B19D54; angle_lut[ 30]=32'h2321A1BD; angle_lut[ 31]=32'h238FA3DC;
        angle_lut[ 32]=32'h23FBBFEB; angle_lut[ 33]=32'h24661043; angle_lut[ 34]=32'h24CEA3F1; angle_lut[ 35]=32'h253589AA;
        angle_lut[ 36]=32'h259AE3A2; angle_lut[ 37]=32'h25FEC698; angle_lut[ 38]=32'h266145F0; angle_lut[ 39]=32'h26C273CA;
        angle_lut[ 40]=32'h27226118; angle_lut[ 41]=32'h27811DB3; angle_lut[ 42]=32'h27DEB872; angle_lut[ 43]=32'h283B36A3;
        angle_lut[ 44]=32'h2896776F; angle_lut[ 45]=32'h28F0BCFB; angle_lut[ 46]=32'h294A12FE; angle_lut[ 47]=32'h29A28470;
        angle_lut[ 48]=32'h29FA1B93; angle_lut[ 49]=32'h2A50ACE9; angle_lut[ 50]=32'h2AA663CB; angle_lut[ 51]=32'h2AFB5CAE;
        angle_lut[ 52]=32'h2B4F9FA6; angle_lut[ 53]=32'h2BA31F13; angle_lut[ 54]=32'h2BF5C037; angle_lut[ 55]=32'h2C47C2C4;
        angle_lut[ 56]=32'h2C992D0A; angle_lut[ 57]=32'h2CE9EBF8; angle_lut[ 58]=32'h2D39E9B0; angle_lut[ 59]=32'h2D896266;
        angle_lut[ 60]=32'h2DD85AF7; angle_lut[ 61]=32'h2E26A2CE; angle_lut[ 62]=32'h2E745C81; angle_lut[ 63]=32'h2EC1A5FC;
        angle_lut[ 64]=32'h2F0E6E76; angle_lut[ 65]=32'h2F5A9643; angle_lut[ 66]=32'h2FA65BB9; angle_lut[ 67]=32'h2FF1C09B;
        angle_lut[ 68]=32'h303C7ED1; angle_lut[ 69]=32'h3086E6C7; angle_lut[ 70]=32'h30D0FAD8; angle_lut[ 71]=32'h311A7AEF;
        angle_lut[ 72]=32'h3163A7E6; angle_lut[ 73]=32'h31AC8AF1; angle_lut[ 74]=32'h31F4E628; angle_lut[ 75]=32'h323CF718;
        angle_lut[ 76]=32'h3284C6C5; angle_lut[ 77]=32'h32CC13E2; angle_lut[ 78]=32'h3313249E; angle_lut[ 79]=32'h3359F2DD;
        angle_lut[ 80]=32'h33A05044; angle_lut[ 81]=32'h33E679DC; angle_lut[ 82]=32'h342C5A17; angle_lut[ 83]=32'h3471E109;
        angle_lut[ 84]=32'h34B73A19; angle_lut[ 85]=32'h34FC4077; angle_lut[ 86]=32'h3541063B; angle_lut[ 87]=32'h3585A334;
        angle_lut[ 88]=32'h35C9E301; angle_lut[ 89]=32'h360DFAD8; angle_lut[ 90]=32'h3651DE58; angle_lut[ 91]=32'h36957A00;
        angle_lut[ 92]=32'h36D8F565; angle_lut[ 93]=32'h371C2DD3; angle_lut[ 94]=32'h375F3997; angle_lut[ 95]=32'h37A22315;
        angle_lut[ 96]=32'h37E4C750; angle_lut[ 97]=32'h3827523F; angle_lut[ 98]=32'h3869AAB2; angle_lut[ 99]=32'h38ABD955;
        angle_lut[100]=32'h38EDEF88; angle_lut[101]=32'h392FC947; angle_lut[102]=32'h39718F6A; angle_lut[103]=32'h39B32D5E;
        angle_lut[104]=32'h39F4A8C9; angle_lut[105]=32'h3A3610A1; angle_lut[106]=32'h3A77482C; angle_lut[107]=32'h3AB870CB;
        angle_lut[108]=32'h3AF97830; angle_lut[109]=32'h3B3A6645; angle_lut[110]=32'h3B7B433E; angle_lut[111]=32'h3BBBFD31;
        angle_lut[112]=32'h3BFCAC1D; angle_lut[113]=32'h3C3D3FA7; angle_lut[114]=32'h3C7DC322; angle_lut[115]=32'h3CBE3798;
        angle_lut[116]=32'h3CFE95B8; angle_lut[117]=32'h3D3EEC24; angle_lut[118]=32'h3D7F2D94; angle_lut[119]=32'h3DBF66DF;
        angle_lut[120]=32'h3DFF9453; angle_lut[121]=32'h3E3FB659; angle_lut[122]=32'h3E7FD379; angle_lut[123]=32'h3EBFE408;
        angle_lut[124]=32'h3EFFF1F0; angle_lut[125]=32'h3F3FF954; angle_lut[126]=32'h3F7FFDA1; angle_lut[127]=32'h3FBFFF97;
        angle_lut[128]=32'h40000000; angle_lut[129]=32'h40400069; angle_lut[130]=32'h4080025F; angle_lut[131]=32'h40C006AC;
        angle_lut[132]=32'h41000E10; angle_lut[133]=32'h41401BF8; angle_lut[134]=32'h41802C87; angle_lut[135]=32'h41C049A7;
        angle_lut[136]=32'h42006BAD; angle_lut[137]=32'h42409921; angle_lut[138]=32'h4280D26C; angle_lut[139]=32'h42C113DC;
        angle_lut[140]=32'h43016A48; angle_lut[141]=32'h4341C868; angle_lut[142]=32'h43823CDE; angle_lut[143]=32'h43C2C059;
        angle_lut[144]=32'h440353E3; angle_lut[145]=32'h444402CF; angle_lut[146]=32'h4484BCC2; angle_lut[147]=32'h44C599BB;
        angle_lut[148]=32'h450687D0; angle_lut[149]=32'h45478F35; angle_lut[150]=32'h4588B7D4; angle_lut[151]=32'h45C9EF5F;
        angle_lut[152]=32'h460B5737; angle_lut[153]=32'h464CD2A2; angle_lut[154]=32'h468E7096; angle_lut[155]=32'h46D036B9;
        angle_lut[156]=32'h47121078; angle_lut[157]=32'h475426AB; angle_lut[158]=32'h4796554E; angle_lut[159]=32'h47D8ADC1;
        angle_lut[160]=32'h481B38B0; angle_lut[161]=32'h485DDCEB; angle_lut[162]=32'h48A0C669; angle_lut[163]=32'h48E3D22D;
        angle_lut[164]=32'h49270A9B; angle_lut[165]=32'h496A8600; angle_lut[166]=32'h49AE21A8; angle_lut[167]=32'h49F20528;
        angle_lut[168]=32'h4A361CFF; angle_lut[169]=32'h4A7A5CCC; angle_lut[170]=32'h4ABEF9C5; angle_lut[171]=32'h4B03BF89;
        angle_lut[172]=32'h4B48C5E7; angle_lut[173]=32'h4B8E1EF7; angle_lut[174]=32'h4BD3A5E9; angle_lut[175]=32'h4C198624;
        angle_lut[176]=32'h4C5FAFBC; angle_lut[177]=32'h4CA60D23; angle_lut[178]=32'h4CECDB62; angle_lut[179]=32'h4D33EC1E;
        angle_lut[180]=32'h4D7B393B; angle_lut[181]=32'h4DC308E8; angle_lut[182]=32'h4E0B19D8; angle_lut[183]=32'h4E53750F;
        angle_lut[184]=32'h4E9C581A; angle_lut[185]=32'h4EE58511; angle_lut[186]=32'h4F2F0528; angle_lut[187]=32'h4F791939;
        angle_lut[188]=32'h4FC3812F; angle_lut[189]=32'h500E3F65; angle_lut[190]=32'h5059A447; angle_lut[191]=32'h50A569BD;
        angle_lut[192]=32'h50F1918A; angle_lut[193]=32'h513E5A04; angle_lut[194]=32'h518BA37F; angle_lut[195]=32'h51D95D32;
        angle_lut[196]=32'h5227A509; angle_lut[197]=32'h52769D9A; angle_lut[198]=32'h52C61650; angle_lut[199]=32'h53161408;
        angle_lut[200]=32'h5366D2F6; angle_lut[201]=32'h53B83D3C; angle_lut[202]=32'h540A3FC9; angle_lut[203]=32'h545CE0ED;
        angle_lut[204]=32'h54B0605A; angle_lut[205]=32'h5504A352; angle_lut[206]=32'h55599C35; angle_lut[207]=32'h55AF5317;
        angle_lut[208]=32'h5605E46D; angle_lut[209]=32'h565D7B90; angle_lut[210]=32'h56B5ED02; angle_lut[211]=32'h570F4305;
        angle_lut[212]=32'h57698891; angle_lut[213]=32'h57C4C95D; angle_lut[214]=32'h5821478E; angle_lut[215]=32'h587EE24D;
        angle_lut[216]=32'h58DD9EE8; angle_lut[217]=32'h593D8C36; angle_lut[218]=32'h599EBA10; angle_lut[219]=32'h5A013968;
        angle_lut[220]=32'h5A651C5E; angle_lut[221]=32'h5ACA7656; angle_lut[222]=32'h5B315C0F; angle_lut[223]=32'h5B99EFBD;
        angle_lut[224]=32'h5C044015; angle_lut[225]=32'h5C705C24; angle_lut[226]=32'h5CDE5E43; angle_lut[227]=32'h5D4E62AC;
        angle_lut[228]=32'h5DC087A9; angle_lut[229]=32'h5E350EF7; angle_lut[230]=32'h5EAC085A; angle_lut[231]=32'h5F259A57;
        angle_lut[232]=32'h5FA1EEF7; angle_lut[233]=32'h6021337E; angle_lut[234]=32'h60A398B3; angle_lut[235]=32'h6129532F;
        angle_lut[236]=32'h61B326E6; angle_lut[237]=32'h6240FB32; angle_lut[238]=32'h62D2FE56; angle_lut[239]=32'h636A16A1;
        angle_lut[240]=32'h64068EFA; angle_lut[241]=32'h64A8BD58; angle_lut[242]=32'h6551DC17; angle_lut[243]=32'h6602414C;
        angle_lut[244]=32'h66BAD4CB; angle_lut[245]=32'h677D9BE9; angle_lut[246]=32'h684B65A5; angle_lut[247]=32'h69263FBE;
        angle_lut[248]=32'h6A10B04F; angle_lut[249]=32'h6B0E21F3; angle_lut[250]=32'h6C24227D; angle_lut[251]=32'h6D58EB92;
        angle_lut[252]=32'h6EB80DDE; angle_lut[253]=32'h70555015; angle_lut[254]=32'h72585B8E; angle_lut[255]=32'h7531CDE0;
        angle_lut[256]=32'h80000000;
    end

    wire [31:0] angle0 = angle_lut[lut_idx];
    wire [31:0] angle1 = angle_lut[lut_idx + 8'd1];
    wire [31:0] angle_delta = angle1 - angle0;
    wire signed [63:0] frac_ext = $signed({32'b0, frac});
    wire signed [63:0] delta_ext = $signed({{32{angle_delta[31]}}, angle_delta});
    wire signed [63:0] prod = frac_ext * delta_ext;
    wire [31:0] angle_xi = angle0 + prod[63:32];

    wire [31:0] cosxi, sinxi;
    wire        cordic_valid;
    cordic_32 u_cordic (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (vdc7_valid),
        .angle (angle_xi),
        .cos   (cosxi),
        .sin   (sinxi),
        .valid (cordic_valid)
    );

    reg [1:0] state;
    reg       sphere_done, cordic_done;
    reg [31:0] sinxi_r, sx_r, sy_r, sz_r, cosxi_r;
    localparam S_IDLE = 0, S_WAIT = 1, S_DONE = 2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 0; state <= S_IDLE;
            sphere_done <= 0; cordic_done <= 0;
            sinxi_r <= 0; sx_r <= 0; sy_r <= 0; sz_r <= 0; cosxi_r <= 0;
        end else begin
            if (sphere_valid) begin
                sphere_done <= 1;
                sx_r <= sx; sy_r <= sy; sz_r <= sz;
            end
            if (cordic_valid) begin
                cordic_done <= 1;
                sinxi_r <= sinxi; cosxi_r <= cosxi;
            end
            case (state)
                S_IDLE: if (en) begin
                    state <= S_WAIT;
                end
                S_WAIT: if (sphere_done && cordic_done) begin
                    valid <= 1; state <= S_DONE;
                    sphere_done <= 0; cordic_done <= 0;
                end
                S_DONE: begin
                    valid <= 0;
                    if (en) begin state <= S_WAIT; end
                    else begin state <= S_IDLE; end
                end
            endcase
        end
    end

    wire [31:0] ax_r = sx_r[31] ? (~sx_r + 1'b1) : sx_r;
    wire [31:0] ay_r = sy_r[31] ? (~sy_r + 1'b1) : sy_r;
    wire [31:0] az_r = sz_r[31] ? (~sz_r + 1'b1) : sz_r;
    wire [31:0] asin_r = sinxi_r[31] ? (~sinxi_r + 1'b1) : sinxi_r;
    wire [63:0] prod_xr = asin_r * ax_r;
    wire [63:0] prod_yr = asin_r * ay_r;
    wire [63:0] prod_zr = asin_r * az_r;
    wire prod_sign_xr = sinxi_r[31] ^ sx_r[31];
    wire prod_sign_yr = sinxi_r[31] ^ sy_r[31];
    wire prod_sign_zr = sinxi_r[31] ^ sz_r[31];
    wire [31:0] x_final = prod_sign_xr ? (~prod_xr[62:31] + 1'b1) : prod_xr[62:31];
    wire [31:0] y_final = prod_sign_yr ? (~prod_yr[62:31] + 1'b1) : prod_yr[62:31];
    wire [31:0] z_final = prod_sign_zr ? (~prod_zr[62:31] + 1'b1) : prod_zr[62:31];

    assign x = x_final;
    assign y = y_final;
    assign z = z_final;
    assign w = cosxi_r;


endmodule
