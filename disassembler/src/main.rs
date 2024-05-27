use clap::Parser;
use std::fmt::Display;
use std::fs::{write, File};
use std::io::{BufRead, BufReader};

#[repr(u8)]
#[derive(PartialEq, Eq)]
enum Opcode {
    R = 0b0110011,
    I1 = 0b0010011,
    I2 = 0b0000011,
    S = 0b0100011,
    B = 0b1100011,
    J = 0b1101111,
    I3 = 0b1100111,
    U1 = 0b0110111,
    U2 = 0b0010111,
    I4 = 0b1110011,
}

impl TryFrom<u8> for Opcode {
    type Error = String;
    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0b0110011 => Ok(Self::R),
            0b0010011 => Ok(Self::I1),
            0b0000011 => Ok(Self::I2),
            0b0100011 => Ok(Self::S),
            0b1100011 => Ok(Self::B),
            0b1101111 => Ok(Self::J),
            0b1100111 => Ok(Self::I3),
            0b0110111 => Ok(Self::U1),
            0b0010111 => Ok(Self::U2),
            0b1110011 => Ok(Self::I4),
            _ => Err(format!("cannot convert {value:#b} to Opcode")),
        }
    }
}

#[derive(Debug, PartialEq, Eq)]
enum InstructionFmt {
    R {
        name: &'static str,
        rs1: u8,
        rs2: u8,
        rd: u8,
    },
    I {
        name: &'static str,
        imm: i32,
        rs1: u8,
        rd: u8,
    },
    S {
        name: &'static str,
        imm: i32,
        rs1: u8,
        rs2: u8,
    },
    B {
        name: &'static str,
        imm: i32,
        rs1: u8,
        rs2: u8,
    },
    U {
        name: &'static str,
        imm: i32,
        rd: u8,
    },
    J {
        name: &'static str,
        imm: i32,
        rd: u8,
    },
}

impl Display for InstructionFmt {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            InstructionFmt::R { name, rs1, rs2, rd } => {
                write!(
                    f,
                    "{name:<6}  {rs1:#04X}  {rs2:#04X}  {}  {rd:#04X}",
                    " ".repeat(10)
                )
            }
            InstructionFmt::I { name, imm, rs1, rd } => {
                write!(
                    f,
                    "{name:<6}  {rs1:#04X}        {imm:<#10X}  {rd:#04X}  {imm}"
                )
            }
            InstructionFmt::S {
                name,
                imm,
                rs1,
                rs2,
            } => write!(
                f,
                "{name:<6}  {rs1:#04X}  {rs2:#04X}  {imm:<#10X}        {imm}"
            ),
            InstructionFmt::B {
                name,
                imm,
                rs1,
                rs2,
            } => write!(
                f,
                "{name:<6}  {rs1:#04X}  {rs2:#04X}  {imm:<#10X}        {imm}"
            ),
            InstructionFmt::U { name, imm, rd } => {
                write!(f, "{name:<6}              {imm:<#10X}  {rd:#04X}  {imm}")
            }
            InstructionFmt::J { name, imm, rd } => {
                write!(f, "{name:<6}              {imm:<#10X}  {rd:#04X}  {imm}")
            }
        }
    }
}

fn rd(value: u32) -> u8 {
    ((value >> 7) & 0x1f) as u8
}

fn rs1(value: u32) -> u8 {
    ((value >> 15) & 0x1f) as u8
}

fn rs2(value: u32) -> u8 {
    ((value >> 20) & 0x1f) as u8
}

fn funct7(value: u32) -> u8 {
    ((value >> 25) & 0x7f) as u8
}

fn i_imm(value: u32) -> i32 {
    let mut imm = value >> 20;
    if value >> 31 == 1 {
        imm = imm + (0xf << 12);
    }
    ((imm as u16) as i16) as i32
}

fn s_imm(value: u32) -> i32 {
    let mut imm = ((value >> 25) << 5) + ((value >> 7) & 0x1f);
    if value >> 31 == 1 {
        imm = imm + (0xf << 12);
    }
    ((imm as u16) as i16) as i32
}

fn u_imm(value: u32) -> i32 {
    ((value >> 12) << 12) as i32
}

fn b_imm(value: u32) -> i32 {
    let mut imm = (value >> 31) << 12;
    imm += ((value >> 7) & 0x1) << 11;
    imm += ((value >> 8) & 0xf) << 1;
    imm += ((value >> 25) & 0x3f) << 5;

    if value >> 31 == 1 {
        imm = imm + (0x7 << 13);
    }

    ((imm as u16) as i16) as i32
}

fn j_imm(value: u32) -> i32 {
    let mut imm = (value >> 31) << 20;
    imm += ((value >> 20) & 0x1) << 11;
    imm += ((value >> 21) & 0x3ff) << 1;
    imm += ((value >> 12) & 0xff) << 12;

    if value >> 31 == 1 {
        imm = imm + (0x7ff << 21);
    }

    imm as i32
}

impl InstructionFmt {
    fn from_u32(value: u32, line: usize) -> Self {
        let opcode = Opcode::try_from((value & 0x7f) as u8)
            .map_err(|e| format!("{e} (line {line})"))
            .unwrap();
        let func3 = (value >> 12) & 0x7;

        match opcode {
            Opcode::R => {
                let func7 = funct7(value);
                let name = match (func3, func7) {
                    (0x0, 0x00) => "add",
                    (0x0, 0x20) => "sub",
                    (0x4, 0x00) => "xor",
                    (0x6, 0x00) => "or",
                    (0x7, 0x00) => "and",
                    (0x1, 0x00) => "sll",
                    (0x5, 0x00) => "srl",
                    (0x5, 0x20) => "sra",
                    (0x2, 0x00) => "slt",
                    (0x3, 0x00) => "sltu",
                    _ => panic!("no ix found for: {value:#02X}, OPCODE: {:#b}, func3: {func3:#02X}, func7: {func7:#02X} (line {line})", opcode as u8)
                };

                Self::R {
                    name,
                    rs1: rs1(value),
                    rs2: rs2(value),
                    rd: rd(value),
                }
            }
            Opcode::I1 => {
                let disc = value >> 20;

                let name = match func3 {
                    0x0 => "addi",
                    0x4 => "xori",
                    0x6 => "ori",
                    0x7 => "andi",
                    0x1 => "slli",
                    0x5 if disc == 0 => "srli",
                    0x5 => "srai",
                    0x2 => "slti",
                    0x3 => "sltiu",
                    _ => panic!(
                        "no ix found for: {value:#02X}, OPCODE: {:#b}, func3: {func3:#02X} (line {line})",
                        opcode as u8
                    ),
                };

                Self::I {
                    name,
                    imm: i_imm(value),
                    rs1: rs1(value),
                    rd: rd(value),
                }
            }
            Opcode::I2 => {
                let name = match func3 {
                    0x0 => "lb",
                    0x1 => "lh",
                    0x2 => "lw",
                    0x4 => "lbu",
                    0x5 => "lhu",
                    _ => panic!(
                        "no ix found for: {value:#02X}, OPCODE: {:#b}, func3: {func3:#02X} (line {line})",
                        opcode as u8
                    ),
                };

                Self::I {
                    name,
                    imm: i_imm(value),
                    rs1: rs1(value),
                    rd: rd(value),
                }
            }
            Opcode::S => {
                let name = match func3 {
                    0x0 => "sb",
                    0x1 => "sh",
                    0x2 => "sw",
                    _ => panic!(
                        "no ix found for: {value:#02X}, OPCODE: {:#b}, func3: {func3:#02X} (line {line})",
                        opcode as u8
                    ),
                };

                Self::S {
                    name,
                    imm: s_imm(value),
                    rs1: rs1(value),
                    rs2: rs2(value),
                }
            }
            Opcode::B => {
                let name = match func3 {
                    0x0 => "beq",
                    0x1 => "bne",
                    0x4 => "blt",
                    0x5 => "bge",
                    0x6 => "bltu",
                    0x7 => "bgeu",
                    _ => panic!(
                        "no ix found for: {value:#02X}, OPCODE: {:#b}, func3: {func3:#02X} (line {line})",
                        opcode as u8
                    ),
                };

                Self::B {
                    name,
                    imm: b_imm(value),
                    rs1: rs1(value),
                    rs2: rs2(value),
                }
            }
            Opcode::J => Self::J {
                name: "jal",
                imm: j_imm(value),
                rd: rd(value),
            },
            Opcode::I3 => Self::I {
                name: "jalr",
                imm: i_imm(value),
                rs1: rs1(value),
                rd: rd(value),
            },
            Opcode::U1 => Self::U {
                name: "lui",
                imm: u_imm(value),
                rd: rd(value),
            },
            Opcode::U2 => Self::U {
                name: "auipc",
                imm: u_imm(value),
                rd: rd(value),
            },
            Opcode::I4 => {
                let name = match (value >> 20) & 0x1 {
                    0x0 => "ecall",
                    0x1 => "ebreak",
                    _ => unreachable!(),
                };

                Self::I {
                    name,
                    imm: i_imm(value),
                    rs1: rs1(value),
                    rd: rd(value),
                }
            }
        }
    }
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    infile: String,

    #[arg(short, long)]
    outfile: Option<String>,

    #[arg(short, long)]
    quiet: bool,
}

fn main() {
    // let t = 0b10000110u8;
    // println!("{t} - {t:#b}");
    // let x = t as i8;
    // println!("{x:#b} - {x}");

    let args = Args::parse();

    let reader = BufReader::new(File::open(&args.infile).unwrap());
    let mut v = vec!["start name    rs1   rs2   imm         rd    signed imm\n".to_string()];

    let mut n = 0;
    for line in reader.lines() {
        let line = line.unwrap();
        let value = u32::from_str_radix(&line, 16).unwrap();
        if value == 0 {
            break;
        }
        let ix = InstructionFmt::from_u32(value, n + 1);
        // if let InstructionFmt::J { imm, .. } = ix {
        //     println!("{value:#034b} | {value} | {imm:#02X}");
        // }
        v.push(format!("{:>4x}  {}", n * 4, ix));
        n += 1;
    }

    let st = v.join("\n");
    if let Some(o) = args.outfile {
        write(&o, st.as_bytes()).unwrap();
    }

    if !args.quiet {
        println!("{st}");
    }
}
