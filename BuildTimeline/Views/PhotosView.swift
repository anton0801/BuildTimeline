import SwiftUI
import UIKit

// MARK: - Global Photos Gallery
struct PhotosView: View {
    @EnvironmentObject var dataStore: DataStore

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var allPhotos: [(photo: PhotoItem, phase: Phase, project: Project)] {
        dataStore.allPhotos.sorted { $0.photo.date > $1.photo.date }
    }

    var body: some View {
        Group {
            if allPhotos.isEmpty {
                BTEmptyState(
                    icon: "photo.on.rectangle.angled",
                    title: "No Photos Yet",
                    subtitle: "Add photos from inside any project phase to document your build progress."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(allPhotos, id: \.photo.id) { item in
                            PhotoGalleryCell(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PhotoGalleryCell: View {
    @EnvironmentObject var dataStore: DataStore
    let item: (photo: PhotoItem, phase: Phase, project: Project)
    @State private var showDetail = false
    @State private var showDelete = false

    var body: some View {
        Button(action: { showDetail = true }) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let data = item.photo.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                    } else {
                        Color(.systemGray5)
                        VStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.btTextSecondary.opacity(0.4))
                            Text(item.photo.caption.isEmpty ? "Photo" : item.photo.caption)
                                .font(.btCaption2())
                                .foregroundColor(.btTextSecondary.opacity(0.6))
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .frame(height: 120)
                .clipped()

                // Overlay info
                if !item.photo.caption.isEmpty {
                    LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                   startPoint: .top, endPoint: .bottom)
                    Text(item.photo.caption)
                        .font(.btCaption2()).foregroundColor(.white)
                        .padding(5)
                }
            }
            .frame(height: 120)
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            VStack {
                Text("\(item.project.name) · \(item.phase.name)")
                    .font(.btCaption())
            }
            Button(role: .destructive) { showDelete = true } label: {
                Label("Delete Photo", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            PhotoDetailView(item: item)
        }
        .alert("Delete Photo", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                dataStore.deletePhoto(item.photo, phaseId: item.phase.id, projectId: item.project.id)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Photo Detail
struct PhotoDetailView: View {
    @Environment(\.presentationMode) var dismiss
    let item: (photo: PhotoItem, phase: Phase, project: Project)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Full photo
                ZStack {
                    Color.black.ignoresSafeArea()
                    if let data = item.photo.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white.opacity(0.4))
                            Text("No image data").font(.btSubhead()).foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                // Info bar
                VStack(alignment: .leading, spacing: 10) {
                    if !item.photo.caption.isEmpty {
                        Text(item.photo.caption)
                            .font(.btHeadline()).foregroundColor(.primary)
                    }
                    HStack(spacing: 16) {
                        Label(item.project.name, systemImage: "folder.fill")
                            .font(.btCaption()).foregroundColor(.btPrimary)
                        Label(item.phase.name, systemImage: "rectangle.stack.fill")
                            .font(.btCaption()).foregroundColor(.btTextSecondary)
                        Label(item.photo.date.btFormatted, systemImage: "calendar")
                            .font(.btCaption()).foregroundColor(.btTextSecondary)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.btPrimary)
                }
            }
        }
    }
}

// MARK: - Add Photo
struct AddPhotoView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var dismiss
    let phase: Phase
    let project: Project

    @State private var caption    = ""
    @State private var imageData: Data? = nil
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var uiImage: UIImage? = nil
    @State private var error      = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.btPrimary).frame(width: 60, height: 60)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24)).foregroundColor(.white)
                        }
                        Text("Add Photo").font(.btTitle2()).foregroundColor(.primary)
                        Text("Phase: \(phase.name)").font(.btCaption()).foregroundColor(.btTextSecondary)
                    }.padding(.top, 16)

                    // Preview or placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: 220)

                        if let img = uiImage {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 44))
                                    .foregroundColor(.btTextSecondary.opacity(0.5))
                                Text("Tap to select a photo")
                                    .font(.btSubhead()).foregroundColor(.btTextSecondary)
                            }
                        }
                    }
                    .onTapGesture { showPicker = true }

                    // Source picker buttons
                    HStack(spacing: 12) {
                        BTButton(title: "Photo Library", icon: "photo.on.rectangle", style: .outline) {
                            pickerSource = .photoLibrary; showPicker = true
                        }
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            BTButton(title: "Camera", icon: "camera.fill", style: .outline) {
                                pickerSource = .camera; showPicker = true
                            }
                        }
                    }

                    BTTextField(placeholder: "Caption (optional)", text: $caption,
                                icon: "text.bubble.fill")

                    if !error.isEmpty {
                        Text(error).font(.btSubhead()).foregroundColor(.btDanger)
                    }

                    BTButton(title: "Save Photo", icon: "checkmark.circle.fill") { save() }
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.btPrimary)
                }
            }
            .sheet(isPresented: $showPicker) {
                ImagePickerView(image: $uiImage, sourceType: pickerSource)
            }
            .onChange(of: uiImage) { img in
                if let img { imageData = img.jpegData(compressionQuality: 0.7) }
            }
        }
    }

    private func save() {
        let photo = PhotoItem(
            id: UUID(), phaseId: phase.id,
            caption: caption.trimmingCharacters(in: .whitespaces),
            date: Date(), imageData: imageData
        )
        dataStore.addPhoto(photo, phaseId: phase.id, projectId: project.id)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - UIImagePickerController wrapper
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        init(_ p: ImagePickerView) { parent = p }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
